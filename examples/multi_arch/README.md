# Examples: Multi Architecture Containers and External binaries

Example how to build multi architecture containers and how to use external binaries.

_Distroless Container Image with Kubectl_

Dependencies:

```yaml
binaries:
  kubectl:
    sha256:
      amd64: 2d0f5ba6faa787878b642c151ccb2c3390ce4c1e6c8e2b59568b3869ba407c4f
      arm64: 1d77d6027fc8dfed772609ad9bd68f611b7e4ce73afa949f27084ad3a92b15fe
    url: https://dl.k8s.io/release/v{version}/bin/linux/{arch}/kubectl
    version: 1.23.0
    tests:
      args: ["version", "--client"]
      output: ['GitVersion:"v{version}"']
```

Validate _arm64_ Container Image:

```bash
bazel run container_test_arm64
INFO: Analyzed target //:container_test_arm64 (86 packages loaded, 1220 targets configured).
INFO: Found 1 target...
Target //:container_test_arm64 up-to-date:
  bazel-bin/container_test_arm64.sh
INFO: Elapsed time: 2.315s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Running command line: external/bazel_tools/tools/test/test-setup.sh ./container_test_arm64.sh
exec ${PAGER:-/usr/bin/less} "$0" || exit 1
Executing tests from //:container_test_arm64
-----------------------------------------------------------------------------

===================================
====== Test file: tests.yaml ======
===================================
=== RUN: Command Test: check-kubectl
--- PASS
duration: 348.012333ms
stdout: Client Version: version.Info{Major:"1", Minor:"23", GitVersion:"v1.23.0", GitCommit:"ab69524f795c42094a6630298ff53f3c3ebab7f4", GitTreeState:"clean", BuildDate:"2021-12-07T18:16:20Z", GoVersion:"go1.17.3", Compiler:"gc", Platform:"linux/arm64"}


===================================
============= RESULTS =============
===================================
Passes:      1
Failures:    0
Duration:    348.012333ms
Total tests: 1

PASS
```
