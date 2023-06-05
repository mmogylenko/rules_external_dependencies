#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_external_dependencies-${TAG:1}"
ARCHIVE="rules_external_dependencies-$TAG.tar.gz"
ARTIFACTS_DIR="dist"

cat > "external_dependencies/versions.bzl" <<EEOF
"Mirror of release info"
# AUTO GENERATED

PARSER_VERSIONS = {
    "${TAG}": {
        "darwin_amd64": "$(sha256sum ${ARTIFACTS_DIR}/parser_darwin_amd64 | cut -d " " -f 1 )",
        "darwin_arm64": "$(sha256sum ${ARTIFACTS_DIR}/parser_darwin_arm64 | cut -d " " -f 1 )",
        "linux_amd64": "$(sha256sum ${ARTIFACTS_DIR}/parser_linux_amd64 | cut -d " " -f 1 )",
        "linux_arm64": "$(sha256sum ${ARTIFACTS_DIR}/parser_linux_arm64 | cut -d " " -f 1 )",
    },
}
EEOF

git archive --format=tar --prefix=${PREFIX}/ --add-file external_dependencies/versions.bzl ${TAG}:external_dependencies | gzip > $ARTIFACTS_DIR/$ARCHIVE
SHA=$(shasum -a 256 $ARTIFACTS_DIR/$ARCHIVE | awk '{print $1}')

cat << EOF
WORKSPACE snippet:

\`\`\`starlark

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_external_dependencies",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/mmogylenko/rules_external_dependencies/releases/download/${TAG}/${ARCHIVE}",
)

load("@rules_external_dependencies//:repositories.bzl", "external_dependencies_repositories")

external_dependencies_repositories()
EOF

echo "\`\`\`"