# SDV application development with Bazel in Yocto

This document describes how a **Software-Defined-Vehicle (SDV)** application is
developed with **Bazel** (C/C++/Python) in this repository and integrated into
the Yocto image pipeline. It preserves Bazel's advantages — hermetic builds,
remote caching, and fast incremental rebuilds — so the same setup scales from a
small service to a large C++ codebase.

## Chosen application and rationale

The repository previously shipped only placeholder layers, so this is a
greenfield integration. Two well-known SDV families fit the C/C++/Python +
Bazel + "large C++ future" requirement:

- **Baidu Apollo** (`ApolloAuto/apollo`) — the canonical large, Bazel-native,
  C++/Python autonomous-driving platform. It is the best showcase of Bazel's
  value on a big C++ tree, but it is heavy to cross-compile and boot.
- **COVESA VSS / Eclipse KUKSA** — a much smaller, vehicle-data-centric SDV
  stack (signal specifications and a data broker). Easy to cross-compile and
  run on `qemux86-64`, and still a recognized SDV project.

To get a working end-to-end vertical slice first, this repository ships a small
**COVESA VSS / KUKSA-style vehicle-signal service** under
`apps/sdv-vehicle-service`, structured so the same Bazel + Yocto mechanism
scales up to an Apollo-sized tree. The application is intentionally
dependency-light (native Bazel `cc_*` rules + Python standard library) so it
builds with no external network fetches — which matters inside Yocto, where the
network is disabled during the build.

## The two build loops

The same Bazel configuration (`MODULE.bazel`, `.bazelrc`, `.bazelversion`) is
shared by both loops.

### Inner loop — developer / devcontainer (native)

Fast iteration on a workstation, Codespace, or devcontainer:

```bash
bazel build //apps/sdv-vehicle-service/...
bazel test  //apps/sdv-vehicle-service/...
bazel run   //apps/sdv-vehicle-service:sdv-vehicle-service -- --once
bazel run   //apps/sdv-vehicle-service:vehicle-cli -- list
```

Bazel/Bazelisk is installed by `scripts/bootstrap-worker-packages.sh` (also run
during `.devcontainer/Dockerfile` image build). `.bazelversion` pins the exact
Bazel release, so every environment uses the same toolchain. The CI workflow
`.github/workflows/bazel-sdv-app.yml` runs this loop on every push/PR that
touches `apps/` — separate from the heavy Yocto build.

### Outer loop — Yocto image (cross-compiled)

The layer `layers/meta-sdv` packages the application into the target image. The
recipe `recipes-sdv/sdv-vehicle-service/sdv-vehicle-service_0.1.bb` drives the
same Bazel build under BitBake (the **Bazel-driven-by-BitBake** integration
mode), cross-compiling against the Yocto toolchain, then installs:

- the C++ service binary at `${bindir}/sdv-vehicle-service`,
- the Python CLI at `${bindir}/vehicle-cli` (+ module under `${libdir}`),
- a systemd unit `sdv-vehicle-service.service` (auto-enabled).

## Bazel ↔ Yocto cross-compilation bridge

The integration relies on Bazel honouring the compiler environment that BitBake
already exports for the target `MACHINE`:

1. BitBake sets `CC`, `CXX`, `CFLAGS`, `CXXFLAGS`, `LDFLAGS` (and the target
   sysroot) in the recipe environment.
2. The recipe exports those variables and invokes
   `bazel build --config=yocto-cross ...`.
3. The shared `.bazelrc` `yocto-cross` profile forwards them into Bazel actions
   via `--action_env=CC/CXX/...` and `--incompatible_strict_action_env`, so
   Bazel's auto-configured C++ toolchain uses the cross compiler.

For Python, the CLI is pure standard library and runs on the target's `python3`
(`RDEPENDS` on `python3-core`); no extension modules are cross-built, so there
is nothing ABI-specific to compile.

### Alternative integration mode

The recipe uses **Bazel-driven-by-BitBake** (most Yocto-native). The simpler
**prebuilt-artifact** mode — build with Bazel in the devcontainer/CI and have a
recipe consume the artifacts — is a drop-in alternative if you want to get an
image green before investing in the in-recipe toolchain wiring.

## Offline dependency strategy

Yocto runs `do_compile` with the network disabled (`BB_NO_NETWORK=1`). Bazel,
by contrast, likes to fetch external modules (from the Bazel Central Registry)
on demand. To keep the build reproducible and offline:

- The sample C++ targets use Bazel's **native** `cc_*` rules and need no
  external repositories at all.
- When external modules are introduced (as the C++ tree grows), mirror their
  archives ahead of time and serve them with `--distdir`. The recipe passes
  `--distdir=${SDV_BAZEL_DISTDIR}` (default `${DL_DIR}/bazel-distdir`) when that
  directory exists. Populate it during a networked fetch step (analogous to
  BitBake's `do_fetch`) or commit a vendored set.
- Bazel state is confined to `${WORKDIR}` via `--output_base`, so builds are
  isolated and do not leak host paths.

## Caching tiers (large-codebase performance)

This complements the repository's existing three Yocto cache tiers (Docker
layers, `downloads`, `sstate`) with a Bazel cache tier:

| Tier | Mechanism | Scope |
|---|---|---|
| Disk cache | `.bazelrc` `--disk_cache` | Local incremental rebuilds |
| Repository cache | `.bazelrc` `--repository_cache` | Fetched external archives |
| CI cache | `actions/cache` in `bazel-sdv-app.yml` | Cross-run reuse on runners |
| Remote cache (opt-in) | `.bazelrc` `--config=remote-cache` | Team-wide / `--remote_download_minimal` |

The remote cache is checked in but disabled by default; enable it once a cache
endpoint (bazel-remote, BuildBuddy, etc.) is provisioned.

## Adding the application to an image

1. Add the layer to `conf/bblayers.conf` (already in
   `conf/bblayers.conf.example`):
   `${YOCTO_PROJECT_ROOT}/layers/meta-sdv`.
2. In `conf/local.conf`, enable systemd and install the app (see the commented
   block in `conf/local.conf.example`):

   ```
   DISTRO_FEATURES:append = " systemd"
   IMAGE_INSTALL:append = " sdv-vehicle-service"
   ```

   Or install the package group: `IMAGE_INSTALL:append = " packagegroup-sdv"`.
3. Pin the recipe `SRCREV` to a known-good commit before building. The recipe
   defaults to `AUTOREV`, but it fails fast unless you explicitly opt in by
   setting `SDV_ALLOW_AUTOREV=1`.

After image build and boot, `sdv-vehicle-service.service` should be present and
auto-started by systemd.

## Scaling up to Apollo (or another large C++ app)

The same structure scales: point a new recipe (or this one's `SDV_APP_GIT_URI`
/ `SDV_BAZEL_PACKAGE`) at the larger Bazel workspace, vendor its external
dependencies into the `--distdir` mirror, and rely on the disk/remote cache to
keep incremental cross-compiles fast.
