workspace(name = "com_github_nbramblett_bazel_mockery")

# The lines below are the typical ones that you will want to include in your own
# WORKSPACE file in order to enable the rules from 'gomockery.bzl' to function
# as expected.
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_skylib",
    sha256 = "64ad2728ccdd2044216e4cec7815918b7bb3bb28c95b7e9d951f9d4eccb07625",
    strip_prefix = "bazel-skylib-1.0.2",
    url = "https://github.com/bazelbuild/bazel-skylib/archive/1.0.2.zip",
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
bazel_skylib_workspace()

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "69de5c704a05ff37862f7e0f5534d4f479418afc21806c887db544a316f3cb6b",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.27.0/rules_go-v0.27.0.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.27.0/rules_go-v0.27.0.tar.gz",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "6148b0430093ccff298f17c1bcf555f449fa35ea90e0c96d3324cd97c75d48f7",
    strip_prefix = "bazel-gazelle-50712ce78b4843fc8620278075383e1ca53dfd74",
    url = "https://github.com/yext/bazel-gazelle/archive/50712ce78b4843fc8620278075383e1ca53dfd74.zip",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
go_rules_dependencies()

go_register_toolchains(
    go_version = "1.16.4",
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")
gazelle_dependencies()

go_repository(
    name = "com_github_vektra_mockery",
    importpath = "github.com/vektra/mockery",
    tag = "e78b021dcbb558a8e7ac1fc5bc757ad7c277bb81",
)

go_repository(
    name = "com_github_stretchr_testify",
    importpath = "github.com/stretchr/testify",
    tag = "363ebb24d041ccea8068222281c2e963e997b9dc",
)

go_repository(
        name = "org_golang_x_mod",
        importpath = "golang.org/x/mod",
        commit = "2addee1ccfb22349ab47953a3046338e461eb4d1",
    )