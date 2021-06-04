load("@io_bazel_rules_go//go:def.bzl", "go_context", "go_path")
load("@io_bazel_rules_go//go/private:providers.bzl", "GoLibrary", "GoPath")

_STRINGER_TOOL = "@org_golang_x_tools//cmd/stringer"

def _go_stringer_impl(ctx):
    go_ctx = go_context(ctx)
    gopath = "$(pwd)/" + ctx.var["BINDIR"] + "/" + ctx.attr.gopath_dep[GoPath].gopath
    inputs = [ctx.file._stringer_tool, go_ctx.go] + (
        ctx.attr.gopath_dep.files.to_list() +
        go_ctx.sdk.headers + go_ctx.sdk.srcs + go_ctx.sdk.tools
    )
    ctx.actions.run_shell(
        outputs = [ctx.outputs.out],
        inputs = inputs,
        tools = [ctx.executable._stringer_tool],
        command = """
           export GOPATH={gopath} &&
           source <($PWD/{godir}/go env) &&
           export GOROOT=`$PWD/{godir}/go env GOROOT` &&
           export PATH=$GOROOT/bin:$PWD/{godir}:$PATH &&
           export GOCACHE=$PWD/gocache &&
           {stringer} -type {type} $GOPATH/src/{importpath} &&
           mv $GOPATH/src/{importpath}/{output_base} {output}
        """.format(
            godir = go_ctx.go.path[:-1 - len(go_ctx.go.basename)],
            gopath = gopath,
            stringer = "$(pwd)/" + ctx.file._stringer_tool.path,
            type = ctx.attr.type,
            importpath = ctx.attr.library[GoLibrary].importpath,
            output = ctx.outputs.out.path,
            output_base = ctx.outputs.out.basename,
        ),
    )

_go_generate_stringer = rule(
    attrs = {
        "library": attr.label(
            doc = "The Go library to process with stringer.",
            providers = [GoLibrary],
            mandatory = True,
        ),
        "type": attr.string(
            doc = "The type to generate a String function for",
            mandatory = True,
        ),
        "out": attr.output(
            doc = "The new Go file to emit the generated mocks into. Set by the macro to TYPE_string.go.",
            mandatory = True,
        ),
        "gopath_dep": attr.label(
            doc = "The go_path label to use to create the GOPATH for the given library. Set by the macro.",
            providers = [GoPath],
            mandatory = False,
        ),
        "_stringer_tool": attr.label(
            doc = "The stringer tool to run",
            default = Label(_STRINGER_TOOL),
            allow_single_file = True,
            executable = True,
            cfg = "host",
            mandatory = False,
        ),
    },
    implementation = _go_stringer_impl,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)

def go_generate_stringer(name, library, type, **kwargs):
    gopath_name = name + "_gostringer_gopath"
    go_path(
        name = gopath_name,
        deps = [library, _STRINGER_TOOL],
        include_data = False,
    )

    _go_generate_stringer(
        name = name,
        library = library,
        type = type,
        gopath_dep = gopath_name,
        out = type.lower() + "_string.go",
        **kwargs
    )