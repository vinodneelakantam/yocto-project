# Architecture

## High-Level Intent

This project separates coordination from compute:

- Coordination happens in GitHub (code, workflow control, visibility).
- Compute happens on external workers (VPS, AWS Spot, or similar) for Yocto/BitBake execution.

For visual summaries, see:

| Diagram | PNG | DOT source |
|---|---|---|
| Architecture overview (top-level) | `docs/diagrams/architecture-overview.png` | `docs/diagrams/architecture-overview.dot` |
| Remote CI pipeline (step-by-step) | `docs/diagrams/ci-remote-pipeline.png` | `docs/diagrams/ci-remote-pipeline.dot` |
| GHCR image lifecycle | `docs/diagrams/ghcr-image-lifecycle.png` | `docs/diagrams/ghcr-image-lifecycle.dot` |
| Cache strategy (three tiers) | `docs/diagrams/cache-layers.png` | `docs/diagrams/cache-layers.dot` |

## Model

- GitHub: source of truth, CI orchestration, logs, and artifacts
- External compute workers: Yocto build execution environment (ephemeral or persistent)
- Repository: stores layer metadata, scripts, docs, and workflow definitions

## Collaboration View

1. Developers collaborate through this repository (commits and workflow dispatch).
2. GitHub Actions orchestrates remote build steps.
3. External worker performs the actual Yocto build using repo content and submodules.
4. Artifacts return to GitHub for shared visibility and download.

## Build Data Flow

Primary multi-stage model:

1. PR validation (`pr-validation.yml`) for fast feedback.
2. Integration build (`remote-yocto-build.yml`) on `main` and `release/*`.
3. Nightly full rebuild (`nightly-full-build.yml`) with clean build mode.
4. Release build (`release-build.yml`) with compliance and CVE gate.
5. Artifact promotion (`artifact-promotion.yml`) from `dev` to `qa` to `prod`.

`remote-yocto-build.yml` has two jobs (parallel-capable):

**Remote build (primary — GitHub-hosted runner):**
1. Push to `main` triggers the `remote-build` job.
2. Disk space is freed on the runner (~25 GB recovered).
3. `actions/cache` restores Yocto `downloads` and `sstate-cache` from previous runs.
4. Submodules are initialized.
5. `scripts/remote-build.sh` runs inside `ghcr.io/<owner>/yocto-build-env` — all tools are
   pre-installed in the image; no package installation at build time.
6. Updated caches are written back via `actions/cache` post-actions.
7. Build outputs are uploaded as GitHub Actions artifacts.

**Codespace build (opt-in — self-hosted runner):**
Activated only on manual dispatch (`run_codespace=true`). Uses the same build
scripts but runs directly inside the prebuilt devcontainer environment.

## Build Responsibility Split

- GitHub Actions (`remote-build` job):
  - Disk cleanup, cache restore/save, submodule init, artifact upload.
  - Yocto build execution runs inside the GHCR container — no apt-get in CI.
- `publish-build-image` workflow:
  - Builds and pushes `ghcr.io/<owner>/yocto-build-env` to GHCR.
  - Triggered on Dockerfile/script changes, weekly schedule, and manual dispatch.
  - Uses Docker buildx layer cache (type=gha) for fast incremental image rebuilds.
- Codespace devcontainer (`local-build` job / interactive dev):
  - Prebuilt image with all tools; local BitBake runs via `scripts/local-build.sh`.

## Cost And Scale Strategy

- Keep GitHub as the frontend for status, logs, and build outputs.
- Use cloud spot instances (for example AWS Spot) when always-on machines are unnecessary.
- Treat workers as disposable to reduce baseline cost.
- Use package-based dependency setup and build caches to keep worker startup and rebuild time low.

## Why This Model

- All build tools are frozen into the GHCR image — no flaky apt installs in CI.
- Docker layer cache (buildx GHA) makes image rebuilds fast after small changes.
- `actions/cache` for `downloads` and `sstate-cache` avoids re-fetching sources and
  recompiling unchanged recipes across runs.
- Disk cleanup on the GitHub-hosted runner frees enough space for a minimal image
  build without requiring paid larger runners.
- GitHub remains the single pane of glass: build status, logs, and artifacts.
- Codespace local builds use the same prebuilt devcontainer image, so local and CI
  tool environments stay in sync.

## Failure Domains

- GHCR image not yet pushed: `publish-build-image.yml` must run at least once before
  `remote-build` can pull the image.
- Disk exhaustion on GitHub-hosted runner: disk cleanup step frees ~25 GB; large
  image targets may still exceed the available ~35–40 GB.
- Missing source submodules: `git submodule update --init --recursive` step must
  succeed; check network access and submodule URLs in `.gitmodules`.
- Stale sstate cache across incompatible toolchain upgrades: bump the cache key
  prefix manually or run with `clean=true` to force a full rebuild.
- Codespace runner not active: `local-build` job will stay queued until the
  Codespace is started; it is opt-in to avoid blocking the workflow.

## Reproducibility Controls

- Build metadata file captures commit SHA, submodule pins, target, and image digests.
- Upstream sources remain pinned by submodule commit.
- Release promotions move immutable artifacts between environments (no rebuild).
