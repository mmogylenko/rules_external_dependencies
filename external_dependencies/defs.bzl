"""
This module contains the implementation to pull in external binaries.
"""

def _config_parser(ctx):
    """A repository rule to load a YAML configuration file into a Starlark dictionary.
    """

    # Check if the output file name has the .bzl extension.
    out_ext = ctx.attr.out[len(ctx.attr.out) - 4:]
    if out_ext != ".bzl":
        fail("Expected output file ({out}) to have .bzl extension".format(out = ctx.attr.out))

    # Get the config absolute path.
    src = ctx.path(ctx.attr.src)

    parser = ctx.path(Label("@extdep_resources//:parser"))
    res = ctx.execute([parser, "-input", src])
    if res.return_code != 0:
        fail(res.stderr)

    # Write the .bzl file with the YAML contents converted.
    ctx.file(ctx.attr.out, res.stdout)

    # An empty BUILD.bazel is only needed to indicate it's a Bazel package.
    ctx.file("BUILD.bazel", "")

config_parser = repository_rule(
    _config_parser,
    doc = "A repository rule to load a YAML configuration file into a Starlark dictionary",
    attrs = {
        "out": attr.string(
            doc = "The output file name",
            mandatory = True,
        ),
        "src": attr.label(
            allow_single_file = True,
            doc = "The YAML file to be loaded into a Starlark dictionary",
            mandatory = True,
        ),
    },
)
