"""
This module contains the implementation to pull in external binaries.
"""

def _external_binary_impl(ctx):
    arch = ctx.attr.architecture

    if arch == "" or arch == None:
        os_arch = ctx.os.arch

    else:
        os_arch = arch

    if os_arch in ["aarch64", "arm64"]:
        os_arch = "arm64"
    elif os_arch in ["x86_64", "amd64"]:
        os_arch = "amd64"
    else:
        fail("Unsupported arch %s" % os_arch)

    if os_arch not in ctx.attr.sha256:
        if os_arch == "amd64":
            dep_arch = "x86_64"
        elif os_arch == "x86_64":
            dep_arch = "amd64"
        else:
            dep_arch = os_arch
    else:
        dep_arch = os_arch

    url = ctx.attr.url.format(version = ctx.attr.version, arch = dep_arch)
    args = {
        "sha256": ctx.attr.sha256[dep_arch],
        "url": url,
    }

    if ctx.attr.strip_prefix != "":
        args["stripPrefix"] = ctx.attr.strip_prefix.format(version = ctx.attr.version, arch = os_arch)

    if ctx.attr.tests:
        env_vars = ctx.attr.tests.get("envVars", [])
        env_vars_formatted = [{"key": e.split("=")[0], "value": e.split("=")[1]} for e in env_vars]
        env_vars_str = ""
        if env_vars:
            env_vars_str = "envVars: {}".format(env_vars_formatted)
        test_filename = "tests.yaml"
        test_contents = """
schemaVersion: "2.0.0"

commandTests:
  - name: "check-{name}"
    command: "{name}"
    args: {args}
    expectedOutput: {output}
    {envVars}
""".format(
            name = ctx.attr.name,
            args = ctx.attr.tests.get("args", []),
            envVars = env_vars_str,
            output = [o.format(version = ctx.attr.version) for o in ctx.attr.tests.get("output", [])],
        )
        ctx.file(test_filename, test_contents)

    if any([url.endswith(suffix) for suffix in [".zip", ".tar.gz", ".tgz", ".tar.bz2", ".tar.xz"]]):
        ctx.download_and_extract(output = ".", **args)
        build_contents = """
        package(default_visibility = ["//visibility:public"])

        load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

        filegroup(
            name = "{name}_filegroup",
            srcs = glob(
                [
                    "**/{name}",
                    "**/{name}.exe",
                ],
            ),
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

        exports_files(["{name}", "tests.yaml"])

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
            doc = "The CPU architecture which the binaries in this image are built to run on. eg: `arm64`, `amd64`",
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
        "tests": attr.string_list_dict(
            mandatory = False,
            doc = "Optional tests for the binary",
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

def external_binary(name, config, architecture = None):
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
