# Bazel as the build-system backbone

This document describes how Bazel is used as the **build-system backbone**
for the SDV applications in this repository — not just to compile a small
service, but to demonstrate the core capabilities of Bazel as a build system:
variant management, layered caching (local, remote, CI), an opt-in remote
execution path, and a cleanly partitioned, independently-buildable,
change-impact-aware dependency graph.

For the application itself (what it does, the two build loops, the Yocto
cross-compilation bridge) see [docs/sdv-bazel-app.md](sdv-bazel-app.md). This
document is scoped to Bazel-the-build-system.

## Build graph partitioning — independent, reusable packages

```
libs/
  vss-common/            # shared VSS-style signal store (cc_library + cc_test)
apps/
  sdv-vehicle-service/    # independent service #1 — depends on //libs/vss-common
  sdv-diagnostics-service/ # independent service #2 — depends on //libs/vss-common
tools/
  variants/               # the build_variant build setting (see below)
```

Each package is independently buildable and testable:

```bash
bazel build //libs/vss-common/...
bazel build //apps/sdv-vehicle-service/...
bazel build //apps/sdv-diagnostics-service/...
bazel test  //...
```

Neither app forks its own copy of the signal store; both declare a `deps` edge
on `//libs/vss-common:signal_store`. This is the "clear partition, better
reuse" model that is meant to scale: as more services are added, each is its
own package/BUILD file, each can be built/tested in isolation, and shared code
lives in one place instead of being copy-pasted. `bazel query` makes the
reuse graph explicit:

```bash
bazel query 'rdeps(//..., //libs/vss-common:signal_store)'
# //apps/sdv-diagnostics-service:diagnostics_rules
# //apps/sdv-diagnostics-service:diagnostics_rules_test
# //apps/sdv-diagnostics-service:sdv-diagnostics-service
# //apps/sdv-vehicle-service:sdv-vehicle-service
# //libs/vss-common:signal_store
# //libs/vss-common:signal_store_test
```

## Independent builds — change-impact analysis

Because the graph is partitioned, only targets that actually (transitively)
depend on what changed need to be rebuilt or retested — not the whole tree.
`scripts/bazel-affected-targets.sh` uses `bazel query`'s `rdeps()` to compute
that set from a git diff:

```bash
scripts/bazel-affected-targets.sh origin/main
```

The CI workflow (`.github/workflows/bazel-sdv-app.yml`) runs this as an
informational, non-blocking step on pull requests, previewing the
change-impact set. A stricter setup could gate `bazel test` on exactly that
target set instead of `//...`; this repo keeps `//...` as the default so the
fast inner loop stays simple, with the affected-targets script available for
larger trees where that starts to matter.

## Variant management (debug / release / secure)

Bazel-level equivalent of the Yocto DISTRO variants in
[layers/meta-portfolio/conf/distro/](../layers/meta-portfolio/conf/distro/)
(`portfolio-debug` / `portfolio-release` / `portfolio-secure`), implemented as
a `string_flag` build setting in [tools/variants/BUILD.bazel](../tools/variants/BUILD.bazel)
(via `bazel_skylib`'s `common_settings.bzl`), consumed through `select()` in
library/binary targets, e.g. [libs/vss-common/BUILD.bazel](../libs/vss-common/BUILD.bazel):

| Variant | `.bazelrc` alias | `compilation_mode` | `strip` | Extra compile/link flags |
|---|---|---|---|---|
| `debug` | `--config=debug` | `dbg` | `never` | `-DSDV_VERBOSE_LOGGING=1` |
| `release` | `--config=release` | `opt` | `always` | none |
| `secure` | `--config=secure` | `opt` | `always` | `-D_FORTIFY_SOURCE=2 -fstack-protector-strong -DSDV_HARDENED=1`, linker `-Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack` |

```bash
bazel build --config=secure //libs/vss-common:signal_store
bazel build --//tools/variants:build_variant=secure //libs/vss-common:signal_store  # equivalent, explicit flag
```

Verify the flags actually reaching the compiler with `bazel aquery`:

```bash
bazel aquery --config=secure 'mnemonic("CppCompile", //libs/vss-common:signal_store)' \
  | grep -o -- '-DSDV_HARDENED=1\|-fstack-protector-strong\|-D_FORTIFY_SOURCE=2'
```

CI builds and tests all three variants as a matrix
(`.github/workflows/bazel-sdv-app.yml`), matching the existing Yocto
`variant-matrix-build` opt-in job for the DISTRO variants
(see [docs/architecture.md](architecture.md#build-variants-debug--release--secure)).

## Caching tiers

| Tier | Mechanism | Scope | Status |
|---|---|---|---|
| Disk cache | `.bazelrc` `--disk_cache` | Local incremental rebuilds | Enabled by default |
| Repository cache | `.bazelrc` `--repository_cache` | Fetched external archives | Enabled by default |
| CI cache | `actions/cache` in `bazel-sdv-app.yml` | Cross-run reuse on runners | Enabled |
| Remote cache (self-hosted) | `.bazelrc` `--config=remote-cache` | Team-wide gRPC cache, opt-in | Real, runnable — see below |
| Remote execution (cloud RBE) | `.bazelrc` `--config=remote-exec` | Offload actions to BuildBuddy, opt-in | Wired, needs an API key to activate |

This is a fourth/fifth cache tier layered on top of the repository's existing
three Yocto cache layers (container layers, `downloads`, `sstate`) — see
[docs/architecture.md](architecture.md#caching-model).

### Remote cache (self-hosted, real)

A local [bazel-remote](https://github.com/buchgr/bazel-remote) instance
(gRPC + HTTP) is defined in
[infra/bazel-remote/docker-compose.yml](../infra/bazel-remote/docker-compose.yml):

```bash
scripts/bazel-remote-cache.sh up      # start (docker compose)
bazel build --config=remote-cache //apps/...
scripts/bazel-remote-cache.sh status  # or: open http://localhost:9090/status
scripts/bazel-remote-cache.sh down    # stop
```

CI runs an equivalent `bazel-remote` service container per job
(`.github/workflows/bazel-sdv-app.yml`) so every variant build/test in the
matrix exercises the same gRPC remote-cache protocol used locally.

### Remote execution (cloud RBE, opt-in)

`--config=remote-exec` points Bazel at
[BuildBuddy](https://www.buildbuddy.io/)'s hosted remote execution + cache +
build-results UI, using the `toolchains_buildbuddy` bzlmod module
(`MODULE.bazel`) for the execution platform/toolchain
(`@toolchains_buildbuddy//platforms:linux_x86_64`). It is wired but inert
without credentials:

```bash
cp buildbuddy.bazelrc.example user.bazelrc   # git-ignored; fill in your API key
bazel build --config=remote-exec //apps/...
bazel test  --config=remote-exec //apps/...
```

`user.bazelrc` is `try-import`ed by `.bazelrc` and git-ignored, so no secret
is ever committed.

## Query / introspection

A cleanly partitioned graph is only useful if it is queryable. A few examples
used throughout this document and useful for day-to-day work on a growing
C++/Python tree:

```bash
# Everything that depends on the shared library (reuse graph):
bazel query 'rdeps(//..., //libs/vss-common:signal_store)'

# Everything the vehicle service depends on (dependency graph):
bazel query 'deps(//apps/sdv-vehicle-service:sdv-vehicle-service)' --output=graph

# All test targets in the workspace:
bazel query 'tests(//...)'

# Change-impact set from a diff (wraps rdeps() over changed packages):
scripts/bazel-affected-targets.sh origin/main
```

## Resume-relevant capabilities demonstrated here

- **Variant management**: a build-setting-driven `select()` axis
  (`debug`/`release`/`secure`) mirroring a real DISTRO-variant strategy,
  verified with `bazel aquery`.
- **Remote caching**: a real, runnable self-hosted gRPC cache
  (bazel-remote via Docker Compose) plus CI wiring, distinct from the local
  disk/repository caches.
- **Remote execution**: RBE wiring (execution platform, toolchain,
  BES/build-results backend) against a cloud RBE provider, activated purely
  by supplying credentials — no code changes needed.
- **Independent, partitioned builds with reuse**: multiple services sharing
  one library through explicit `deps` edges, each independently
  buildable/testable, with `bazel query`/`rdeps()` making the dependency and
  reuse graph explicit and change-impact analysis scriptable.
