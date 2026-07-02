# Repository Deep Dive

This page preserves the detailed content previously present in the top-level
README, while keeping the root README concise.

## Purpose In One View

This repo is the coordination hub and public frontend for the Yocto work.

- Team members push recipe, layer, and app changes here.
- GitHub Actions builds the image and tracks build process end to end.
- Heavy Yocto builds run inside a frozen GHCR container image on a
  GitHub-hosted runner, with optional Codespace or external worker paths.
- Build outputs are returned to GitHub as downloadable workflow artifacts.

See visual diagrams:

| Diagram | PNG | DOT source |
|---|---|---|
| Architecture overview (top-level) | `docs/diagrams/architecture-overview.png` | `docs/diagrams/architecture-overview.dot` |
| Remote CI pipeline (step-by-step) | `docs/diagrams/ci-remote-pipeline.png` | `docs/diagrams/ci-remote-pipeline.dot` |
| GHCR image lifecycle | `docs/diagrams/ghcr-image-lifecycle.png` | `docs/diagrams/ghcr-image-lifecycle.dot` |
| Cache strategy (three tiers) | `docs/diagrams/cache-layers.png` | `docs/diagrams/cache-layers.dot` |
| Repository collaboration (v3) | `docs/diagrams/repo-collaboration-block-diagram-v3.png` | `docs/diagrams/repo-collaboration-block-diagram-v3.dot` |

For inline previews and explanations, see `docs/diagram-gallery.md`.

## Repository Layout

- `apps/`: Bazel-built applications (SDV service)
- `layers/`: Project Yocto layers (`meta-portfolio`, `meta-security`, `meta-ota`, `meta-sdv`)
- `sources/`: Upstream Yocto sources tracked as pinned Git submodules
- `conf/`: Example BitBake configuration templates
- `scripts/`: Build, bootstrap, cache-sync, and GitHub automation scripts
- `docs/`: Architecture, security/OTA, conventions, onboarding, SDV guidance
- `.github/workflows/`: CI workflows
- `.devcontainer/`: Dev Container/Codespaces definition
- `MODULE.bazel`, `.bazelrc`, `.bazelversion`: Bazel module config

## Project Guardrails

- Repository conventions: `docs/repo-conventions.md`
- Contributor onboarding: `docs/onboarding-checklist.md`
- Local build instructions: `docs/local-build.md`
- Architecture deep-dive: `docs/architecture.md`
- Security and OTA design: `docs/security-and-ota.md`
- SDV app with Bazel: `docs/sdv-bazel-app.md`
- Cloud worker placeholder plan: `docs/cloud/aws-spot-worker-plan.md`

## CI Workflows

| Workflow | File | Purpose |
|---|---|---|
| Yocto Build | `.github/workflows/remote-yocto-build.yml` | Primary image build path; includes opt-in Codespace job. |
| Publish Yocto Build Image | `.github/workflows/publish-build-image.yml` | Builds/pushes `ghcr.io/<owner>/yocto-build-env` from devcontainer Dockerfile. |
| Bazel SDV App | `.github/workflows/bazel-sdv-app.yml` | Fast app build/test (no Yocto). |
| Docs HTML | `.github/workflows/docs-html.yml` | Builds consolidated docs HTML artifact. |
| Docs Pages Deploy | `.github/workflows/docs-pages.yml` | Publishes docs site to GitHub Pages. |
| Sync Yocto Cache | `.github/workflows/seed-cache-from-codespace.yml` | Bidirectional Codespace/GitHub cache sync. |
| Build Health Dashboard | `.github/workflows/build-health-dashboard.yml` | Native CI observability in job summary. |

## End-to-End Yocto Build Flow

The Yocto Build workflow runs on push to `main` (or manual dispatch).

Remote build path (primary):
1. Trigger by push/dispatch.
2. Ensure GHCR build image exists.
3. Free runner disk space.
4. Compute submodule revision hash for cache keying.
5. Restore `downloads` and `sstate-cache`.
6. Initialize submodules.
7. Run `scripts/remote-build.sh` inside `ghcr.io/<owner>/yocto-build-env`.
8. Save updated caches.
9. Upload build artifacts.

Codespace path (opt-in):
- Runs on manual dispatch with `run_codespace=true` if a Codespace runner is active.

## Compute Model

- Primary: GitHub-hosted runner + GHCR containerized toolchain.
- Optional: self-hosted Codespace runner.
- Future: disposable external workers (VPS/AWS Spot) using same scripts.

## Build Cache Reuse

Three cache tiers are used:

| Layer | Mechanism | What is cached |
|---|---|---|
| Docker image layers | `publish-build-image.yml` + buildx `type=gha` | Yocto tool packages and image layers |
| Yocto source tarballs | `actions/cache` -> `.cache/yocto/downloads` | Upstream source archives |
| Yocto sstate | `actions/cache` -> `.cache/yocto/sstate-cache` | Incremental build objects |

Optional central cache for local/non-runner environments:

```bash
export YOCTO_CENTRAL_CACHE_RSYNC="<user>@<host>:/srv/yocto-cache"
```

Prepare central host directories:

```bash
ssh <user>@<host> "mkdir -p /srv/yocto-cache/downloads /srv/yocto-cache/sstate-cache"
```

## SDV Application

`apps/sdv-vehicle-service` is a COVESA VSS / Eclipse KUKSA-style service built
with Bazel.

- Inner loop: native build/test (`bazel test //apps/...`)
- Outer loop: Yocto recipe in `layers/meta-sdv/recipes-sdv/sdv-vehicle-service`
  cross-builds and packages binary, Python CLI, and systemd unit.

See `apps/sdv-vehicle-service/README.md` and `docs/sdv-bazel-app.md`.

## Why Submodules

- Keeps local project history clean and separate from upstream code.
- Preserves explicit upstream provenance.
- Makes upstream updates intentional and reviewable.

## What This Repo Is Not

- Not a fork of `yoctoproject/poky`
- Not a mirror of `openembedded/meta-openembedded`
- Not intended to contain full upstream history directly

## Quick Start

1. Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/<owner>/<repo>.git
cd <repo>
```

If needed after cloning:

```bash
git submodule update --init --recursive
```

2. Populate Yocto config templates (`conf/local.conf.example`, `conf/bblayers.conf.example`).
3. Trigger build by pushing to `main` or manual workflow dispatch.

Trigger once via CLI:

```bash
export GH_REPO="owner/repo"
./scripts/github/run-workflow-once.sh
```

## Docs Build Output

Build docs HTML locally:

```bash
./scripts/build-docs-html.sh
```

Output path: `out/docs-html/index.html`.

CI also publishes docs to GitHub Pages via `.github/workflows/docs-pages.yml`.

## Security Notes

- Never commit private/signing keys.
- Keep signing material on restricted infrastructure.
- Use least-privilege users for any CI-triggered worker actions.

See `docs/security-and-ota.md`.

## Codespaces Reuse

This repository includes `.devcontainer/` with preinstalled worker dependencies
and Bazelisk.

Recommended setup:
1. Enable Codespaces prebuilds for `main`.
2. Use default devcontainer configuration.
3. Keep prebuilds enabled for your target region/machine profile.
