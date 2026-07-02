# Yocto Build Control Repository

This repository is the control plane for a Yocto-based build platform.

What it does now:
- Builds Yocto images using GitHub Actions and containerized build tooling.
- Maintains project-specific Yocto layers and config templates.
- Hosts an SDV sample application built with Bazel and packaged through Yocto.
- Publishes build artifacts and documentation from CI.

What it is moving toward:
- Multi-backend worker execution (GitHub-hosted, Codespace, and cloud spot workers).
- Stronger supply-chain controls (signing, verification, release promotion rules).
- OTA-ready release lifecycle with rollback safety.

## Quick Start

1. Clone with submodules.

```bash
git clone --recurse-submodules https://github.com/<owner>/<repo>.git
cd <repo>
```

2. Run a local Yocto build.

```bash
./scripts/local-build.sh core-image-minimal false
```

3. Build and test the SDV app.

```bash
bazel test //apps/sdv-vehicle-service/...
```

## Documentation Map

| If you need... | Read |
|---|---|
| Current architecture and roadmap boundaries | `docs/architecture.md` |
| Day-1 contributor setup | `docs/onboarding-checklist.md` |
| Local build operation and troubleshooting | `docs/local-build.md` |
| Repository standards and change rules | `docs/repo-conventions.md` |
| Security and OTA posture (current vs planned) | `docs/security-and-ota.md` |
| SDV Bazel + Yocto integration details | `docs/sdv-bazel-app.md` |
| Visual diagrams and pipeline flow | `docs/diagram-gallery.md` |

Published docs site: https://vinodneelakantam.github.io/yocto-project/

## Repository Scope

- `apps/`: Bazel-built SDV services and tests
- `layers/`: Yocto layers owned by this project
- `sources/`: pinned upstream submodules (`poky`, `meta-openembedded`)
- `conf/`: example `local.conf` and `bblayers.conf` templates
- `scripts/`: local/CI build and automation helpers
- `docs/`: project documentation source

## Non-Goals

- This repository is not a fork or mirror of upstream Yocto trees.
- This repository does not store private signing keys.
- This repository does not require always-on self-hosted infrastructure.
