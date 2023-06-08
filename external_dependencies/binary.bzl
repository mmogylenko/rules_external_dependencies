"""
This module contains the implementation to pull in external binaries.
"""

def _external_binary_impl(ctx):
    archs = ctx.attr.sha256.keys()
    exports_files_list = []

    for arch in archs:
        _normalized_name = "{}_{}".format(ctx.attr.name, arch.replace("x86_64", "amd64"))
        url = ctx.attr.url.format(version = ctx.attr.version, arch = arch)
        args = {
            "sha256": ctx.attr.sha256[arch],
            "url": url,
        }
        if ctx.attr.strip_prefix != "":
            args["stripPrefix"] = ctx.attr.strip_prefix.format(version = ctx.attr.version, arch = arch)
        if any([url.endswith(suffix) for suffix in [".zip", ".tar.gz", ".tgz", ".tar.bz2", ".tar.xz"]]):
            ctx.report_progress("Downloading {} from".format(ctx.attr.name, url))
            ctx.download_and_extract(
                output = ".",
                #rename_files = {rename_from: _normalized_name},
                **args
            )
            ctx.execute(["mv", ctx.attr.name, _normalized_name])

            exports_files_list.append(_normalized_name)
        else:
            args["executable"] = True
            ctx.download(output = _normalized_name, **args)
            exports_files_list.append(_normalized_name)

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
        exports_files_list.append(test_filename)

    build_contents = """
    package(default_visibility = ["//visibility:public"])

    exports_files({exports_files_list})
    """.format(exports_files_list = exports_files_list)

    build_contents = "\n".join([x.lstrip(" ") for x in build_contents.splitlines()])
    ctx.file("BUILD.bazel", build_contents, executable = True)

_external_binary = repository_rule(
    implementation = _external_binary_impl,
    attrs = {
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

def external_binary(name, config):
    _external_binary(
        name = name,
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
