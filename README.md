# Yocto GitHub-Centric Build Project

This repository implements a GitHub-first workflow for Yocto development:
- GitHub is the control and visibility layer for your recipes/apps and build history
- External compute is the build execution layer (VPS, AWS Spot, or similar)
- Artifacts and logs are always published back to GitHub Actions

## Purpose In One View

This repo is the coordination hub and public frontend for your Yocto work.

- Team members push recipes/app changes here.
- GitHub Actions starts and tracks the build process.
- Heavy Yocto builds run on external compute when GitHub/Codespaces resources are not enough.
- Build outputs are returned to GitHub as artifacts for review/download.

See the visual block diagrams:

| Diagram | PNG | DOT source |
|---|---|---|
| Architecture overview (top-level) | `docs/diagrams/architecture-overview.png` | `docs/diagrams/architecture-overview.dot` |
| Remote CI pipeline (step-by-step) | `docs/diagrams/ci-remote-pipeline.png` | `docs/diagrams/ci-remote-pipeline.dot` |
| GHCR image lifecycle | `docs/diagrams/ghcr-image-lifecycle.png` | `docs/diagrams/ghcr-image-lifecycle.dot` |
| Cache strategy (three tiers) | `docs/diagrams/cache-layers.png` | `docs/diagrams/cache-layers.dot` |

## Repository Layout

- `apps/`: Bazel-built applications (e.g. the SDV vehicle-signal service)
- `layers/`: Yocto layers and custom metadata
- `conf/`: Example build configuration templates
- `scripts/`: Automation scripts for remote build and artifact flow
- `docs/`: Architecture, security, OTA, and operations notes
- `.github/workflows/`: CI workflows that orchestrate remote builds

## Project Guardrails

- Repository conventions: `docs/repo-conventions.md`
- Contributor onboarding: `docs/onboarding-checklist.md`
- Cloud worker placeholder plan: `docs/cloud/aws-spot-worker-plan.md`
- Local build instructions: `docs/local-build.md`
- SDV app development with Bazel: `docs/sdv-bazel-app.md`

## What This Repository Does (Detailed)

This repository is a **Yocto build orchestrator and showcase**, not a full mirror of upstream Yocto source trees.

### Primary responsibilities

- Keep upstream Yocto sources in `sources/` as **Git submodules** (pinned to known commits)
- Store project-specific layers/recipes/apps in `layers/`
- Provide reusable build configuration templates in `conf/`
- Automate remote builds using GitHub Actions with external cost-optimized compute
- Return build outputs to GitHub as downloadable workflow artifacts

### End-to-end workflow

Two parallel jobs run on every push to `main` (or manual dispatch):

**Remote build — primary CI path (GitHub-hosted runner + Docker):**
1. A change is pushed to `main` or the workflow is dispatched.
2. ~25 GB of unused vendor toolchains are removed to make room for Yocto.
3. A submodule revision hash is computed so cache keys track upstream layer pins.
4. `actions/cache` restores Yocto `downloads` and `sstate-cache` from prior runs.
5. Submodules are initialized.
6. BitBake runs inside `ghcr.io/<owner>/yocto-build-env` — all tools are
   pre-installed in the image; no package installation at build time.
7. Updated caches are saved back for the next run.
8. Built images and the build summary are uploaded as GitHub Actions artifacts.

**Codespace build — opt-in (self-hosted runner):**
Available on manual dispatch when a Codespace runner is active
(`run_codespace=true`). Uses the same build scripts and cache paths but
runs directly inside the prebuilt devcontainer.

### What gets built where

- Built on external compute (VPS, AWS Spot, or similar):
	- Yocto image targets (for example `core-image-minimal`)
	- BitBake outputs and logs
	- Full repo checkout plus submodules
	- Compiler/toolchain dependencies installed as packages on build nodes
	- Build cache reuse (`sstate-cache`, `downloads`, and other reusable artifacts)
- Built on GitHub runner:
	- No heavy Yocto compile workload
	- Orchestration tasks only (trigger, sync/bootstrap, collect, upload)

### Compute strategy

- Primary goal: keep GitHub as the single place to view build status, logs, and outputs.
- If GitHub/Codespaces compute is insufficient, run builds on cloud spot machines (for example AWS Spot) to reduce cost.
- Build nodes are treated as disposable workers; checkout and dependency setup happen on demand.
- Caching is used to keep rebuild times and costs low.

### Build Cache Reuse Across Environments

Remote workflow `.github/workflows/remote-yocto-build.yml` manages three cache
layers across runs:

| Layer | Mechanism | What is cached |
|---|---|---|
| Docker image layers | `publish-build-image.yml` + `buildx type=gha` | All Yocto tool packages (apt installs) |
| Yocto source tarballs | `actions/cache` → `.cache/yocto/downloads` | Upstream source archives fetched by BitBake |
| Yocto sstate | `actions/cache` → `.cache/yocto/sstate-cache` | Incremental build objects; avoids recompiling unchanged recipes |

Cache keys include a hash of all pinned submodule commit SHAs so the key
automatically changes when an upstream layer is bumped, while still allowing
fallback to the closest previous run via `restore-keys`.

This makes dependency and build cache reusable across new Codespaces, new runners,
and future workflow runs in the same repository.

For local builds (and any non-GitHub-runner environment), set:

```bash
export YOCTO_CENTRAL_CACHE_RSYNC="<user>@<host>:/srv/yocto-cache"
```

Then run build scripts normally. They will:

- Pull `downloads` and `sstate-cache` from the central location before build
- Push updated cache back after build

Prepare central host directory once:

```bash
ssh <user>@<host> "mkdir -p /srv/yocto-cache/downloads /srv/yocto-cache/sstate-cache"
```

### Why submodules are used

- You keep a clean history of local project changes.
- Upstream layer provenance remains explicit.
- Updating upstream code is intentional and reviewable via submodule commit changes.

### What this repo is not

- Not a fork of `yoctoproject/poky`
- Not a mirror of `openembedded/meta-openembedded`
- Not intended to store all upstream source history directly in this repository

## Quick Start

1. Clone with source submodules:

```bash
git clone --recurse-submodules https://github.com/<owner>/<repo>.git
cd <repo>
```

If already cloned without submodules:

```bash
git submodule update --init --recursive
```

2. Populate Yocto config templates:
- Copy `conf/local.conf.example` to your Yocto build directory
- Copy `conf/bblayers.conf.example` and adjust layer paths

3. Source repositories tracked as submodules:
- `sources/poky` (`yoctoproject/poky`, branch `scarthgap`)
- `sources/meta-openembedded` (`openembedded/meta-openembedded`, branch `scarthgap`)

4. Local layers included in this repository:
- `layers/meta-portfolio`
- `layers/meta-security`
- `layers/meta-ota`
- `layers/meta-sdv` (Bazel-built SDV application; see `docs/sdv-bazel-app.md`)

5. Configure GitHub repository secrets:
- `GITHUB_TOKEN` — automatically provided by GitHub Actions; no manual setup required.
- `YOCTO_CENTRAL_CACHE_RSYNC` (optional) — rsync URI for a shared cache server
  (example: `user@host:/srv/yocto-cache`). When set, `remote-build.sh` syncs
  `downloads` and `sstate-cache` to/from that server in addition to `actions/cache`.

> **Note — GHCR image prerequisite:** The `remote-build` CI job pulls
> `ghcr.io/<owner>/yocto-build-env:latest`. Run the
> **Publish Yocto Build Image** workflow manually once (or push a change to
> `.devcontainer/Dockerfile`) to build and push the image before the first
> remote build runs.

6. Trigger a remote build:
- Push to `main`, or
- Run workflow `Remote Yocto Build` manually from Actions tab

Or trigger once by CLI:

```bash
export GH_REPO="owner/repo"
./scripts/github/run-workflow-once.sh
```

## Security Notes

- Do not commit private keys or signing keys
- Keep signing material on secure infrastructure (HSM or restricted key host)
- Use least-privilege VPS user for CI-triggered operations

## Next Steps

- Add your real layer manifests in `layers/`
- Implement signing and OTA pipeline from `docs/security-and-ota.md`
- Extend workflow with release tagging and artifact retention policy

## Codespaces Reuse (No Reinstall Every Time)

This repository now includes a Dev Container definition at `.devcontainer/`.
The container image installs Yocto worker dependencies during image build time
(including `zstd` which provides `pzstd`).

To make this reusable across new Codespaces in GitHub:

1. Open repository **Settings -> Codespaces -> Prebuild configurations**.
2. Create a prebuild for branch `main` using the default `.devcontainer/devcontainer.json`.
3. Keep prebuilds enabled for the regions and machine type you use.
4. Recommended machine is defined in `.devcontainer/devcontainer.json` as 8 CPUs and 16 GB RAM.

With prebuilds enabled, new Codespaces pull the cached prebuilt image instead of
running package installs from scratch.
