load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_context", "go_path")
load("@io_bazel_rules_go//go/private:providers.bzl", "GoLibrary", "GoPath", "GoSource")
load("@bazel_skylib//lib:paths.bzl", "paths")

_MOCKERY_TOOL = "@com_github_vektra_mockery//cmd/mockery:mockery"
_TESTIFY_MOCK_LIB = "@com_github_stretchr_testify//mock:go_default_library"

_LIB_DEFAULT_LABEL = "go_default_library"
_MOCKS_DEFAULT_LABEL = "go_mock_library"
_MOCKS_GOPATH_LABEL = "_mocks_gopath"


def go_mockery(name, src, importpath, interfaces, deps=[], **kwargs):
    """Runs Mockery on a Go library
    See https://github.com/vektra/mockery for details

    Args:
        name: The name of the generated go_library
        src: The Go Library to use as a source target
        importpath: The path which will be used in a Go file's import statement
            in order to call the generated mock package
        interfaces: The set of interfaces for which a mocked type will be generated
        deps: list of bazel dependencies needed by the generated go_library
    """
    mocks_name = kwargs.get("mocks_name", _MOCKS_DEFAULT_LABEL)

    go_mockery_without_library(
        name = mocks_name,
        src = src,
        interfaces = interfaces,
        case = kwargs.get("case", "underscore"),
        outpkg = kwargs.get("outpkg", importpath.split("/")[-1]),
        mockery_tool = kwargs.get("mockery_tool", None),
    )

    go_library(
        name = name,
        srcs = [mocks_name],
        importpath = importpath,
        deps = deps + [
            kwargs.get("testify_mock_lib", _TESTIFY_MOCK_LIB),
        ],
    )

def go_mockery_without_library(src, interfaces, **kwargs):
    """Runs Mockery on a Go library, but does not create a Go library.
    Useful for cases where the mock lib acts as an intermediate source in bazel,
    rather than a usable Go package.
    See https://github.com/vektra/mockery for details

    Args:
        src: The Go Library to use as a source target
        interfaces: The set of interfaces for which a mocked type will be generated
    """
    interfaces = [ ifce.strip() for ifce in interfaces ]

    outpkg = kwargs.get("outpkg", "mocks")
    genfiles = [ paths.join(outpkg, _interface_to_case(ifce) + ".go") for ifce in interfaces ]

    go_path(
        name = _MOCKS_GOPATH_LABEL,
        deps = [src],
        visibility = ["//visibility:private"]
    )

    _go_mockery(
        name = kwargs.get("name", _MOCKS_DEFAULT_LABEL),
        src = src,
        interfaces = interfaces,
        outpkg = outpkg,
        outputs = genfiles,
        gopath_dep = _MOCKS_GOPATH_LABEL,
        mockery_tool = kwargs.get("mockery_tool", _MOCKERY_TOOL),
    )

def _go_mockery_impl(ctx):
    gopath = ctx.var["BINDIR"] + "/" + ctx.attr.gopath_dep[GoPath].gopath
    args =  ["-dir", gopath + "/src/" + ctx.attr.src[GoLibrary].importpath]
    args += ["-outpkg", ctx.attr.outpkg]
    args += ["-output", ctx.outputs.outputs[0].dirname ]
    args += ["-name", "|".join(ctx.attr.interfaces)]
    args += ["-case", "underscore"]

    _go_tool_run_shell_stdout(
        ctx = ctx,
        cmd = ctx.file.mockery_tool,
        args = args,
        extra_inputs =  ctx.attr.src[GoSource].srcs,
        outputs = ctx.outputs.outputs,
    )

    go = go_context(ctx)
    library = go.new_library(go)

    return [
        library,
        DefaultInfo(
            files = depset(ctx.outputs.outputs),
        ),
    ]

_go_mockery = rule(
    implementation = _go_mockery_impl,
    attrs = {
        "src": attr.label(
            doc = "The Go library where the interfaces being mocked are defined",
            providers = [GoLibrary, GoSource],
            mandatory = True,
        ),
        "interfaces": attr.string_list(
            doc = "The names of the Go interfaces for which to generate mocks. Unlike 'mockery' itself regular expressions are not accepted.",
            mandatory = True,
        ),
        "outpkg": attr.string(
            doc = "Import name for the generated mocks package.",
            default = "mocks",
            mandatory = False,
        ),
        "outputs": attr.output_list(
            doc = "The Go source files that will generated and contain the mocks of the targeted interfaces from the specified package.",
            mandatory = True,
        ),
        "gopath_dep": attr.label(
            doc = "The go_path used to create the GOPATH for the mocks package. Is automatically populated by the gomockery macro.",
            providers = [GoPath],
            mandatory = False,
        ),
        "mockery_tool": attr.label(
            doc = "The target of the mockery tool to run.",
            default = Label(_MOCKERY_TOOL),
            allow_single_file = True,
            executable = True,
            cfg = "host",
            mandatory = False,
        ),
    },
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)

def _go_tool_run_shell_stdout(ctx, cmd, args, extra_inputs, outputs):
    go_ctx = go_context(ctx)
    gopath = "$(pwd)/" + ctx.var["BINDIR"] + "/" + ctx.attr.gopath_dep[GoPath].gopath

    inputs = [ctx.file.mockery_tool, go_ctx.go] + (
        ctx.attr.gopath_dep.files.to_list() +
        go_ctx.sdk.headers + go_ctx.sdk.srcs + go_ctx.sdk.tools
    ) + extra_inputs

    # We can use the go binary from the stdlib for most of the environment
    # variables, but our GOPATH is specific to the library target we were given.
    # We also, unfortunately, need to do some dirty & porcelain sed'ing on the
    # generated mock files as their import header will be messed up.
    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        tools = [cmd],
        command = """
            export GOPATH={gopath} &&
            export GO111MODULE=off &&
            source <($PWD/{godir}/go env) &&
            export GOROOT=`$PWD/{godir}/go env GOROOT` &&
            export PATH=$GOROOT/bin:$PWD/{godir}:$PATH &&
            export GOCACHE=$GOPATH/pkg &&
            {cmd} {args}
        """.format(
            godep = ctx.attr.gopath_dep[GoPath].gopath,
            godir = go_ctx.go.path[:-1 - len(go_ctx.go.basename)],
            gopath = gopath,
            cmd = "$(pwd)/" + cmd.path,
            args = " ".join(args),
            outfiles = " ".join([ outfile.path for outfile in outputs ]),
        )
    )

# This transformation logic should mirror the one used in
# https://github.com/vektra/mockery/blob/master/pkg/outputter.go
# It is relatively challenging given the limitations of the Starlark
# language: no regular expressions and no 'while' loops.
def _interface_to_case(name):
    transformed = ""
    idx = -1

    # We reflect the parsing state via the 'state' variable.
    # 0 - Parsing until the end of a 'Cased' word.
    # 1 - Parsing until the end of a potential uppercase block.
    state = 0

    curr_word_start = 0

    for idx in range(1, len(name)):
        if state == 0:
            if name[idx].isupper():
                if idx == curr_word_start + 1:
                    state = 1
                    continue

                if curr_word_start > 0:
                    transformed += "_"
                transformed += name[curr_word_start:idx].lower()
                curr_word_start = idx
        elif state == 1:
            if not name[idx].isupper():
                if curr_word_start > 0:
                    transformed += "_"
                transformed += name[curr_word_start:idx-1].lower()
                curr_word_start = idx - 1
                state = 0
        else:
            fail("reached an unexpected parsing state")

    if curr_word_start > 0:
        transformed += "_"
    transformed += name[curr_word_start:].lower()

    return transformed
