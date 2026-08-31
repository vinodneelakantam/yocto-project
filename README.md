# Yocto Build Control Repository

![Python](https://img.shields.io/badge/Python-3-3776AB?logo=python&logoColor=white)
![Yocto Project](https://img.shields.io/badge/Yocto%20Project-scarthgap-3E863C?logo=yoctoproject&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-embedded-FCC624?logo=linux&logoColor=black)

This repository is the control plane for a Yocto-based build platform.

What it does now:
- Builds Yocto images using GitHub Actions and containerized build tooling.
- Maintains project-specific Yocto layers and config templates.
- Hosts an SDV sample application built with Bazel and packaged through Yocto.
- Publishes build artifacts and documentation from CI.
- Uses Python helper scripts (`scripts/*.py`) for BitBake log visualization, docs rendering, and SBOM/CVE triage.

What it is moving toward:
- Multi-backend worker execution (GitHub-hosted, Codespace, and cloud spot workers).
- Stronger supply-chain controls (signing, verification, release promotion rules).
- OTA-ready release lifecycle with rollback safety.

## Quick Start

Prerequisites: a Linux host with sufficient CPU/RAM/disk for Yocto, plus Git,
Python 3, and the standard BitBake host packages (see
`scripts/lib/host-requirements.sh`; `scripts/local-build.sh` can auto-install
them).

1. Clone with submodules.

```bash
git clone --recurse-submodules https://github.com/<owner>/<repo>.git
cd <repo>
```

2. Run a local Yocto build.

```bash
./scripts/local-build.sh core-image-minimal false
```

3. Build and test the SDV apps (all variants share one Bazel graph):

```bash
bazel test //...
bazel test --config=secure //...
```

## Documentation Map

| If you need... | Read |
|---|---|
| Current architecture and roadmap boundaries | `docs/architecture.md` |
| Single contributor starting point | `docs/contributor-journey.md` |
| Day-1 contributor setup | `docs/onboarding-checklist.md` |
| Local build operation and troubleshooting | `docs/local-build.md` |
| BitBake log visualization (tasks, recipes, stages) | `docs/bitbake-log-visualization.md` |
| Yocto image outputs and artifact meanings | `docs/image-output-artifacts.md` |
| Repository standards and change rules | `docs/repo-conventions.md` |
| Security and OTA posture (current vs planned) | `docs/security-and-ota.md` |
| SBOM generation and CVE triage pipeline | `docs/sbom-and-cve-workflow.md` |
| Prioritized roadmap to close resume/portfolio gaps | `docs/resume-gap-roadmap.md` |
| SDV Bazel + Yocto integration details | `docs/sdv-bazel-app.md` |
| Bazel as a build-system backbone (variants, remote cache, RBE, partitioning) | `docs/bazel-build-system.md` |
| Visual diagrams and pipeline flow | `docs/diagram-gallery.md` |

Published docs site: https://vinodneelakantam.github.io/yocto-project/

## Repository Scope

- `apps/`: Bazel-built SDV services and tests
- `libs/`: shared Bazel libraries reused across `apps/`
- `tools/`: Bazel build-setting/tooling packages (e.g. variant management)
- `layers/`: Yocto layers owned by this project
- `sources/`: pinned upstream submodules (`poky`, `meta-openembedded`)
- `conf/`: example `local.conf` and `bblayers.conf` templates
- `scripts/`: local/CI build and automation helpers
- `docs/`: project documentation source

## Non-Goals

- This repository is not a fork or mirror of upstream Yocto trees.
- This repository does not store private signing keys.
- This repository does not require always-on self-hosted infrastructure.
