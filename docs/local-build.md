# Local Build Guide

Use this page for local command execution only. For first-time setup sequence,
start with `docs/onboarding-checklist.md`.

## Prerequisites

- Linux host with enough CPU, RAM, and disk for Yocto.
- Repository cloned with submodules.
- Build dependencies installed (or auto-bootstrap enabled).

## Recommended Build Command

From repository root:

```bash
./scripts/local-build.sh core-image-minimal false
```

What this wrapper does:
- refreshes submodules,
- optionally installs host packages,
- executes Yocto build through shared build script,
- stages outputs in `out/`.

## Optional Environment Controls

Disable package bootstrap:

```bash
export BOOTSTRAP_PACKAGES=false
```

Enable shared rsync cache endpoint:

```bash
export YOCTO_CENTRAL_CACHE_RSYNC="<user>@<host>:/srv/yocto-cache"
```

When central cache is set, `downloads` and `sstate-cache` are synchronized
before and after build.

## Direct Build Script (Advanced)

If you need to bypass the wrapper:

```bash
./scripts/remote-build.sh <image-target> <clean>
```

Example:

```bash
./scripts/remote-build.sh core-image-minimal true
```

## Output Locations

After success:
- `out/`
- `out/build-summary.txt`
- `out/images/` (if deploy images were produced)

To understand artifact types and usage in `out/images/<machine>/`, see:
- `docs/image-output-artifacts.md`

## Build Log Visualization

To visualize build progress by task, recipe, and stage from a cooker log:

```bash
./scripts/visualize-bitbake-log.py \
  build/tmp/log/cooker/qemux86-64/<timestamp>.log \
  --out-dir build/tmp/log/cooker/qemux86-64/visualization \
  --dot-dir build
```

Generated outputs:
- `report.html` (dashboard)
- `tasks.csv` (event-level task stream)
- `recipe_stage_summary.csv` (recipe x stage rollup)
- `stage_summary.csv` (global stage rollup)

If Graphviz `dot` is installed and DOT files are present, dependency graphs are
also rendered to SVG from `task-depends.dot` and `pn-depends.dot`.

By default, `scripts/local-build.sh` now runs
`scripts/generate-bitbake-artifacts.sh` after a successful build to produce
both:
- task dependency artifacts compatible with Task Explorer workflows
  (`task-depends.dot`, `pn-depends.dot`, optional SVGs), and
- Python-based cooker-log visualization artifacts (`report.html`, CSV files).

To skip automatic visualization for a run:

```bash
export VISUALIZE_BUILD_LOGS=false
./scripts/local-build.sh
```

## Troubleshooting

- Missing Poky init script:
  - run `git submodule update --init --recursive`.
- Host dependency errors:
  - run `./scripts/bootstrap-worker-packages.sh`.
- Locale error for `en_US.UTF-8`:
  - rerun bootstrap script, then open a new shell.
- Slow rebuilds:
  - avoid clean rebuild unless needed and keep cache directories.

## Related

- Onboarding checklist: `docs/onboarding-checklist.md`
- SDV Bazel + Yocto integration: `docs/sdv-bazel-app.md`
- Yocto image artifacts reference: `docs/image-output-artifacts.md`
- Scripts inventory: `scripts/README.md`
