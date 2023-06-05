"""
This module contains the implementation to pull in external binaries.
"""

def _external_binary_impl(ctx):
    arch = ctx.attr.architecture

    url = ctx.attr.url.format(version = ctx.attr.version, arch = arch)
    args = {
        "sha256": ctx.attr.sha256[arch],
        "url": url,
    }

    if ctx.attr.strip_prefix != "":
        args["stripPrefix"] = ctx.attr.strip_prefix.format(version = ctx.attr.version, arch = arch)

    if any([url.endswith(suffix) for suffix in [".zip", ".tar.gz", ".tgz", ".tar.bz2", ".tar.xz"]]):
        ctx.download_and_extract(output = ".", **args)
        build_contents = """
        package(default_visibility = ["//visibility:public"])

        load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

        filegroup(
            name = "{name}_filegroup",
            srcs = glob([
                "**/{name}",
                "**/{name}.exe",
            ]),
        )

        copy_file(
            name = "binary",
            src = ":{name}_filegroup",
            out = ".binary",
            is_executable = True,
        )

        exports_files(glob(["**/*"]))
        """.format(name = ctx.attr.name)
    else:
        args["executable"] = True
        ctx.download(output = "{name}".format(name = ctx.attr.name), **args)
        build_contents = """
        package(default_visibility = ["//visibility:public"])

        load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

        exports_files(["{name}"])

        copy_file(
            name = "binary",
            src = ":{name}",
            out = ".binary",
            is_executable = True,
        )
        """.format(name = ctx.attr.name)

    build_contents = "\n".join([x.lstrip(" ") for x in build_contents.splitlines()])
    ctx.file("BUILD.bazel", build_contents)

_external_binary = repository_rule(
    implementation = _external_binary_impl,
    attrs = {
        "architecture": attr.string(
            doc = "The CPU architecture which the binaries in this image are built to run on. eg: `arm64`, `arm`, `amd64`",
            default = "@platforms//cpu:current",
            mandatory = False,
        ),
        "sha256": attr.string_dict(
            allow_empty = False,
            doc = "Checksum of the binaries, keyed by os name",
        ),
        "strip_prefix": attr.string(
            mandatory = False,
            doc = "Directory prefixex to strip from the extracted files",
        ),
        "url": attr.string(
            mandatory = True,
            doc = "URL to download the binary from, keyed by platform; {version} will be replaced",
        ),
        "version": attr.string(
            doc = "Version of the binary",
            mandatory = False,
        ),
    },
)

def external_binary(name, architecture, config):
    _external_binary(
        name = name,
        architecture = architecture,
        **config
    )

def _binary_location_impl(ctx):
    script = ctx.actions.declare_file(ctx.attr.name)
    contents = "echo \"$(realpath $(pwd)/{})\"".format(ctx.executable.binary.short_path)
    ctx.actions.write(script, contents, is_executable = True)
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = [ctx.executable.binary]),
    )]

binary_location = rule(
    implementation = _binary_location_impl,
    attrs = {
        "binary": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
    },
    executable = True,
)

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
