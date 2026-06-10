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

## How It Works

1. Developer pushes changes to GitHub.
2. GitHub Actions starts the orchestration workflow.
3. Workflow connects to VPS over SSH.
4. VPS runs Yocto build with BitBake.
5. Build artifacts are uploaded back to GitHub.

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
