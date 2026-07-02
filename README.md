# Yocto GitHub-Centric Build Project

A GitHub-first workflow for building a custom Yocto Linux distribution and the
Software-Defined-Vehicle (SDV) application that ships inside it.

The guiding idea is a clean split between **coordination** and **compute**:

- **GitHub is the coordination layer** — source of truth for recipes, layers,
  and apps; the place where builds are triggered, tracked, and where logs and
  artifacts are published.
- **A reproducible build environment is the compute layer** — BitBake runs
  inside a pre-built container image so the toolchain is identical in CI, in
  Codespaces, and on any external worker.

## Purpose In One View

This repo is the coordination hub and public frontend for the Yocto work.

- Team members push recipe / layer / app changes here.
- GitHub Actions builds the image and tracks the build process end to end.
- Heavy Yocto builds run inside a frozen container image (GHCR) on a
  GitHub-hosted runner, with an opt-in Codespace path and an optional external
  worker path (VPS / AWS Spot) for when more compute is needed.
- Build outputs are returned to GitHub as downloadable workflow artifacts.

See the visual block diagrams:

| Diagram | PNG | DOT source |
|---|---|---|
| Architecture overview (top-level) | `docs/diagrams/architecture-overview.png` | `docs/diagrams/architecture-overview.dot` |
| Remote CI pipeline (step-by-step) | `docs/diagrams/ci-remote-pipeline.png` | `docs/diagrams/ci-remote-pipeline.dot` |
| GHCR image lifecycle | `docs/diagrams/ghcr-image-lifecycle.png` | `docs/diagrams/ghcr-image-lifecycle.dot` |
| Cache strategy (three tiers) | `docs/diagrams/cache-layers.png` | `docs/diagrams/cache-layers.dot` |
| Repository collaboration (v3) | `docs/diagrams/repo-collaboration-block-diagram-v3.png` | `docs/diagrams/repo-collaboration-block-diagram-v3.dot` |

For inline previews and explanations of all diagrams, see
`docs/diagram-gallery.md`.

## Repository Layout

- `apps/`: Bazel-built applications — the SDV vehicle-signal service (C++/Python)
- `layers/`: Project Yocto layers (`meta-portfolio`, `meta-security`, `meta-ota`, `meta-sdv`)
- `sources/`: Upstream Yocto sources tracked as pinned Git submodules
- `conf/`: Example BitBake configuration templates (`local.conf`, `bblayers.conf`)
- `scripts/`: Build, worker-bootstrap, cache-sync, and GitHub automation scripts
- `docs/`: Architecture, security/OTA, conventions, onboarding, and SDV app notes
- `.github/workflows/`: CI workflows that orchestrate builds and image publishing
- `.devcontainer/`: Dev Container / Codespaces definition with all build tools pre-installed
- `MODULE.bazel`, `.bazelrc`, `.bazelversion`: Bazel module config for the `apps/` builds

## Project Guardrails

- Repository conventions: `docs/repo-conventions.md`
- Contributor onboarding: `docs/onboarding-checklist.md`
- Local build instructions: `docs/local-build.md`
- Architecture deep-dive: `docs/architecture.md`
- Security and OTA design: `docs/security-and-ota.md`
- SDV app development with Bazel: `docs/sdv-bazel-app.md`
- Cloud worker placeholder plan: `docs/cloud/aws-spot-worker-plan.md`

## What This Repository Does (Detailed)

This repository is a **Yocto build orchestrator and showcase**, not a full
mirror of upstream Yocto source trees.

### Primary responsibilities

- Keep upstream Yocto sources in `sources/` as **Git submodules** (pinned to known commits)
- Store project-specific layers / recipes / apps in `layers/` and `apps/`
- Provide reusable build configuration templates in `conf/`
- Build the image in CI inside a frozen container so the toolchain never drifts
- Return build outputs to GitHub as downloadable workflow artifacts

### CI workflows

| Workflow | File | Purpose |
|---|---|---|
| **Yocto Build** | `.github/workflows/remote-yocto-build.yml` | Primary image build. Ensures the GHCR image exists, then runs BitBake. Includes an opt-in Codespace job. |
| **Publish Yocto Build Image** | `.github/workflows/publish-build-image.yml` | Builds and pushes `ghcr.io/<owner>/yocto-build-env` from `.devcontainer/Dockerfile`. |
| **Bazel SDV App** | `.github/workflows/bazel-sdv-app.yml` | Fast inner-loop CI: builds and tests the `apps/` C/C++/Python code natively (no Yocto). |
| **Docs HTML** | `.github/workflows/docs-html.yml` | Builds a single consolidated HTML documentation bundle and uploads it as `docs-html` artifact. |
| **Docs Pages Deploy** | `.github/workflows/docs-pages.yml` | Builds the consolidated docs HTML and deploys it to GitHub Pages from Actions. |
| **Sync Yocto Cache** | `.github/workflows/seed-cache-from-codespace.yml` | Bidirectional cache sync between a Codespace and the GitHub Actions cache. |
| **Build Health Dashboard** | `.github/workflows/build-health-dashboard.yml` | Observability: renders a build-health dashboard (last status, success rate, average duration and recent trend per workflow) into the run's Job Summary using only the native Actions REST API. Runs daily and on demand. |

#### Build health dashboard

`build-health-dashboard.yml` provides native CI observability with no third-party
actions or external services. On a daily schedule (and via **Run workflow**) it
queries the GitHub Actions REST API with the preinstalled `gh` CLI and publishes
a dashboard to the run's **Job Summary** (visible on the Actions run page). For
each active workflow on the default branch it reports the latest run status, the
success rate, the average run duration and a recent-outcome trend strip. Use the
`window` input on manual runs to change how many recent runs are analysed.

### End-to-end Yocto build workflow

The **Yocto Build** workflow runs on every push to `main` (or manual dispatch):

**Remote build — primary CI path (GitHub-hosted runner + GHCR container):**
1. A change is pushed to `main` or the workflow is dispatched.
2. `ensure-build-image` confirms `ghcr.io/<owner>/yocto-build-env` exists, and
   builds/pushes it from `.devcontainer/Dockerfile` if it is missing.
3. ~25 GB of unused vendor toolchains are removed to make room for Yocto's `tmp/`.
4. A submodule revision hash is computed so cache keys track upstream layer pins.
5. `actions/cache` restores Yocto `downloads` and per-layer `sstate-cache` from prior runs.
6. Submodules are initialized.
7. `scripts/remote-build.sh` runs BitBake inside `ghcr.io/<owner>/yocto-build-env`
   — all tools are pre-installed in the image; no package installation at build time.
8. Updated caches are saved back for the next run.
9. Built images and the build summary are uploaded as GitHub Actions artifacts.

**Codespace build — opt-in (self-hosted runner):**
Available on manual dispatch when a Codespace runner is active
(`run_codespace=true`). Uses the same build scripts and cache paths but runs
directly inside the prebuilt devcontainer.

### Compute model

- **Primary:** GitHub-hosted `ubuntu-latest` runner executes BitBake inside the
  GHCR container image. This keeps GitHub as the single place to view build
  status, logs, and outputs, with no flaky `apt` installs at build time.
- **Opt-in:** A self-hosted Codespace runner can run the same build interactively.
- **Optional / future:** External cost-optimized compute (VPS or AWS Spot) can
  run the same `scripts/remote-build.sh`. The lifecycle automation for this is a
  placeholder today — see `scripts/cloud/aws-spot-build-placeholder.sh` and
  `docs/cloud/aws-spot-worker-plan.md`. Workers are treated as disposable.

### Where the Yocto compile workload runs

- Inside the GHCR container (on the runner or any worker):
  - Yocto image targets (for example `core-image-minimal`)
  - BitBake outputs and logs
  - Full repo checkout plus submodules
  - Build cache reuse (`sstate-cache`, `downloads`)
- On the bare GitHub runner:
  - No heavy compile workload directly — only orchestration (disk cleanup,
    cache restore/save, submodule init, container launch, artifact upload)

### Build cache reuse across environments

The **Yocto Build** workflow manages three cache layers across runs:

| Layer | Mechanism | What is cached |
|---|---|---|
| Docker image layers | `publish-build-image.yml` + `buildx type=gha` | All Yocto tool packages (apt installs) |
| Yocto source tarballs | `actions/cache` → `.cache/yocto/downloads` | Upstream source archives fetched by BitBake |
| Yocto sstate | `actions/cache` → `.cache/yocto/sstate-cache` | Incremental build objects; avoids recompiling unchanged recipes |

The sstate layer is split into per-layer cache keys (upstream, `meta-portfolio`,
`meta-security`, `meta-ota`). Because sstate files are content-addressed, the
entries merge into one `SSTATE_DIR` conflict-free, and a change to one custom
layer only busts that layer's key. All keys include a hash of the pinned
submodule commit SHAs, so the key changes automatically when an upstream layer
is bumped, while `restore-keys` still allow fallback to the closest previous run.

This makes dependency and build cache reusable across new Codespaces, new
runners, and future workflow runs in the same repository.

For local builds (and any non-GitHub-runner environment), an optional shared
cache server can be used instead of (or alongside) `actions/cache`:

```bash
export YOCTO_CENTRAL_CACHE_RSYNC="<user>@<host>:/srv/yocto-cache"
```

Then run the build scripts normally. They will:

- Pull `downloads` and `sstate-cache` from the central location before build
- Push updated cache back after build

Prepare the central host directory once:

```bash
ssh <user>@<host> "mkdir -p /srv/yocto-cache/downloads /srv/yocto-cache/sstate-cache"
```

### The SDV application

`apps/sdv-vehicle-service` is a small COVESA VSS / Eclipse KUKSA-style
Software-Defined-Vehicle service, built with **Bazel** to exercise the
C/C++/Python toolchain and the Yocto integration. It is dependency-light so it
builds with no network fetches — which keeps it reproducible inside Yocto, where
the network is disabled during the build.

- Inner loop: build and test natively (`bazel test //apps/...`), validated by the
  **Bazel SDV App** workflow.
- Outer loop: the recipe `layers/meta-sdv/recipes-sdv/sdv-vehicle-service` drives
  the same Bazel build with the Yocto SDK cross toolchain and installs the
  binary, the Python CLI, and a systemd unit into the target image.

See `apps/sdv-vehicle-service/README.md` and `docs/sdv-bazel-app.md`.

### Why submodules are used

- A clean history of local project changes is kept separate from upstream code.
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

> **Note — GHCR image prerequisite:** The **Yocto Build** workflow pulls
> `ghcr.io/<owner>/yocto-build-env:latest`. Its `ensure-build-image` job builds
> and pushes the image automatically on the first run if it is missing; you can
> also run the **Publish Yocto Build Image** workflow manually to pre-build it.

6. Trigger a build:
- Push to `main`, or
- Run the **Yocto Build** workflow manually from the Actions tab

Or trigger once by CLI:

```bash
export GH_REPO="owner/repo"
./scripts/github/run-workflow-once.sh
```

### Consolidated HTML docs output

Build a single-file HTML view of repository docs locally:

```bash
./scripts/build-docs-html.sh
```

Output path:

- `out/docs-html/index.html`

In CI, the **Docs HTML** workflow runs on docs changes (or manually) and
uploads the same output folder as the `docs-html` artifact.

The **Docs Pages Deploy** workflow publishes the same output to GitHub Pages.
After the first successful deployment, the site URL is:

- `https://<owner>.github.io/<repo>/`

7. Build and test the SDV app locally (no Yocto required):

```bash
bazel test //apps/sdv-vehicle-service/...
bazel run //apps/sdv-vehicle-service:vehicle-cli -- list
```

## Security Notes

- Do not commit private keys or signing keys
- Keep signing material on secure infrastructure (HSM or restricted key host)
- Use a least-privilege user for any CI-triggered operations on external workers

See `docs/security-and-ota.md` for the signing and OTA design.

## Next Steps

- Add real layer manifests and recipes in `layers/`
- Implement the signing and OTA pipeline from `docs/security-and-ota.md`
- Extend the workflow with release tagging and an artifact retention policy
- Flesh out external-worker automation from `docs/cloud/aws-spot-worker-plan.md`

## Codespaces Reuse (No Reinstall Every Time)

This repository includes a Dev Container definition at `.devcontainer/`.
The container image installs Yocto worker dependencies during image build time
(including `zstd`, which provides `pzstd`) and Bazelisk for the `apps/` builds.

To make this reusable across new Codespaces in GitHub:

1. Open repository **Settings → Codespaces → Prebuild configurations**.
2. Create a prebuild for branch `main` using the default `.devcontainer/devcontainer.json`.
3. Keep prebuilds enabled for the regions and machine type you use.
4. The recommended machine is defined in `.devcontainer/devcontainer.json` (16 CPUs, 32 GB RAM, 128 GB storage).

With prebuilds enabled, new Codespaces pull the cached prebuilt image instead of
running package installs from scratch.
