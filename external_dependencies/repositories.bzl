"""An extension with the workspace dependency declarations."""

load(":versions.bzl", "PARSER_VERSIONS")

LATEST_PARSER_VERSION = PARSER_VERSIONS.keys()[0]

def _repositories_impl(ctx):
    os_arch = ctx.os.arch
    platform = ctx.os.name

    if platform == "mac os x":
        platform = "darwin"
    elif platform != "linux":
        fail("Unsupported OS %s" % platform)

    if os_arch == "aarch64":
        os_arch = "arm64"
    elif os_arch == "x86_64":
        os_arch = "amd64"
    else:
        fail("Unsupported arch %s" % os_arch)

    ctx.download(
        executable = True,
        output = "parser",
        sha256 = PARSER_VERSIONS[LATEST_PARSER_VERSION]["{}_{}".format(platform, os_arch)],
        url = "https://github.com/mmogylenko/rules_external_dependencies/releases/download/{}/parser_{}_{}".format(LATEST_PARSER_VERSION, platform, os_arch),
    )

    ctx.file("BUILD.bazel", 'exports_files(glob(["**/*"]))\n')

_external_dependencies_repositories = repository_rule(_repositories_impl)

def external_dependencies_repositories():
    """A macro for wrapping the workspace_dependencies repository rule with a hardcoded name.

    The workspace_dependencies repository rule should be called before any of the other rules in
    this Bazel extension.
    Hardcoding the target name is useful for consuming it internally. The targets produced by this
    rule are only used within the workspace rules.
    """
    _external_dependencies_repositories(
        name = "extdep_resources",
    )
