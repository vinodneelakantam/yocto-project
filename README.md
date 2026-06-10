# Yocto GitHub-Centric Build Project

This repository implements a GitHub-first workflow for Yocto development:
- GitHub is the control and visibility layer
- External compute (VPS) is the build execution layer
- Artifacts and logs are published back to GitHub

## Repository Layout

- `layers/`: Yocto layers and custom metadata
- `conf/`: Example build configuration templates
- `scripts/`: Automation scripts for remote build and artifact flow
- `docs/`: Architecture, security, OTA, and operations notes
- `.github/workflows/`: CI workflows that orchestrate remote builds

## What This Repository Does (Detailed)

This repository is a **Yocto build orchestrator**, not a full mirror of upstream Yocto source trees.

### Primary responsibilities

- Keep upstream Yocto sources in `sources/` as **Git submodules** (pinned to known commits)
- Store project-specific layers in `layers/`
- Provide reusable build configuration templates in `conf/`
- Automate remote builds using GitHub Actions and VPS execution scripts
- Return build outputs to GitHub as downloadable workflow artifacts

### End-to-end workflow

1. A change is pushed to `main` (or the workflow is started manually).
2. GitHub Actions checks out this repo with submodules recursively.
3. CI prepares SSH credentials (`VPS_SSH_KEY`) and host trust.
4. Repository contents are synced to a VPS build directory.
5. `scripts/remote-build.sh` runs BitBake on the VPS.
6. Built images/logs from `out/` are copied back and uploaded as artifacts.

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

5. Configure GitHub repository secrets:
- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `VPS_PORT` (optional)
- `VPS_BUILD_ROOT` (optional)

Use helper script after `gh auth login`:

```bash
export GH_REPO="owner/repo"
export VPS_HOST="your.vps.host"
export VPS_USER="yocto-ci"
export VPS_SSH_KEY="$(cat ~/.ssh/id_ed25519)"
./scripts/github/set-secrets.sh
```

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
