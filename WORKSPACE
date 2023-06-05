workspace(name = "rules_external_dependencies")

load(":internal_deps.bzl", "internal_deps")

internal_deps()

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("//cmd/parser:deps.bzl", "go_dependencies")

# gazelle:repository_macro cmd/parser/deps.bzl%go_dependencies
go_dependencies()

go_rules_dependencies()

go_register_toolchains(version = "1.20.4")

# gazelle:repo bazel_gazelle
gazelle_dependencies()

load("@buildifier_prebuilt//:deps.bzl", "buildifier_prebuilt_deps")

buildifier_prebuilt_deps()

load("@buildifier_prebuilt//:defs.bzl", "buildifier_prebuilt_register_toolchains")

buildifier_prebuilt_register_toolchains()
