# Local Build Instructions

This project supports running Yocto builds directly on your local machine.

## What You Need

- Linux host with enough CPU, RAM, and disk for Yocto builds.
- Git submodules initialized.
- Required build packages installed.

## 1) Initialize Sources

Run from repository root:

```bash
git submodule update --init --recursive
```

## 2) Install Build Dependencies

Use the helper script:

```bash
./scripts/bootstrap-worker-packages.sh
```

If you do not want auto package install from scripts, you can disable it during build with:

```bash
export BOOTSTRAP_PACKAGES=false
```

## 3) Run Local Build

Optional shared cache (recommended across machines):

```bash
export YOCTO_CENTRAL_CACHE_RSYNC="<user>@<host>:/srv/yocto-cache"
```

When this variable is set, build scripts pull cache before build and push updated
cache after build (`downloads` and `sstate-cache`). This lets local systems,
Codespaces, and remote workers reuse the same dependency cache.

One-command full local build (recommended):

```bash
./scripts/local-build.sh core-image-minimal false
```

This wrapper performs:

- Submodule initialization/update
- Optional package bootstrap
- Yocto build execution

Build default target:

```bash
./scripts/remote-build.sh core-image-minimal false
```

Parameters:

- First argument: image target (example: `core-image-minimal`)
- Second argument: clean flag (`true` or `false`)

Example clean rebuild:

```bash
./scripts/remote-build.sh core-image-minimal true
```

## 4) Find Build Outputs

After success, outputs are staged in:

- `out/`
- `out/build-summary.txt`
- `out/images/` (when deploy images are produced)

## 5) Common Issues

- Missing `sources/poky/oe-init-build-env`:
  - Re-run submodule init/update.
- Dependency/install errors:
  - Re-run `./scripts/bootstrap-worker-packages.sh`.
- Bazelisk download warning during bootstrap:
  - Bootstrap fetches Bazelisk from GitHub Releases and verifies checksum.
  - Re-run `./scripts/bootstrap-worker-packages.sh` after restoring network access.
  - If your environment blocks GitHub, install Bazelisk manually in PATH as `bazelisk` (or `bazel`).
- Locale error `Please make sure locale 'en_US.UTF-8' is available on your system`:
  - Run `./scripts/bootstrap-worker-packages.sh` (it installs `locales` and generates `en_US.UTF-8`).
  - If needed, apply manually:

```bash
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
```

  - Open a new shell and re-run the build.
- Very slow build:
  - Reuse cache directories under `.cache/yocto/` and avoid `clean=true` unless needed.

## 6) Bazel SDV Application (inner loop)

The repository also hosts a Bazel-built SDV application under `apps/`. Bazel
(via Bazelisk) is installed by `./scripts/bootstrap-worker-packages.sh`, pinned
by `.bazelversion`. Build and test it natively for fast iteration:

```bash
bazel build //apps/sdv-vehicle-service/...
bazel test  //apps/sdv-vehicle-service/...
bazel run   //apps/sdv-vehicle-service:sdv-vehicle-service -- --once
```

To cross-compile and package it into a Yocto image, see
`docs/sdv-bazel-app.md` and the `layers/meta-sdv` recipe.

## 7) Build Consolidated HTML Documentation

Generate one HTML file that aggregates repository Markdown documentation:

```bash
./scripts/build-docs-html.sh
```

Output path:

- `out/docs-html/index.html`

Optional custom output path:

```bash
./scripts/build-docs-html.sh out/docs-html/my-docs.html
```
