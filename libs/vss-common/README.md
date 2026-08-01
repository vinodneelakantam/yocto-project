# libs/vss-common

Shared, dependency-free COVESA VSS-style signal store (`SignalStore`), reused
by every independently-built Bazel service under `apps/`
(`sdv-vehicle-service`, `sdv-diagnostics-service`, ...).

This package exists to demonstrate a cleanly partitioned Bazel build graph:
each app is still built and tested independently
(`bazel build //apps/<service>/...`), but they share one implementation
instead of forking it. See [docs/bazel-build-system.md](../../docs/bazel-build-system.md).

```bash
bazel build //libs/vss-common/...
bazel test  //libs/vss-common/...
```

The library's `copts`/`linkopts` are selected on the `//tools/variants:build_variant`
build setting (`debug` / `release` / `secure`), mirroring the Yocto
`portfolio-debug` / `portfolio-release` / `portfolio-secure` DISTRO variants.
