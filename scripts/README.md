# Scripts

Script index for build, setup, and automation helpers in this repository.

Detailed docs site: https://vinodneelakantam.github.io/yocto-project/

## Core Build Scripts

| Script | Purpose | Typical Use |
|---|---|---|
| `local-build.sh` | Local build wrapper with dependency checks/bootstrap and optional cache seed | Developer local build entrypoint |
| `remote-build.sh` | Core Yocto build contract, cache sync, and output staging | Called by workflows and local wrapper |
| `bootstrap-worker-packages.sh` | Installs host packages required for Yocto and Bazel flows | New machine preparation |
| `devcontainer-sanity-check.sh` | Validates required host tools before build | Early failure detection |
| `cache-sync-daemon.sh` | Long-running cache sync helper for shared caches | Optional advanced setup |
| `generate-bitbake-artifacts.sh` | Generates taskexp-related dependency artifacts and Python cooker-log visualization bundle | Post-build analysis bundle |

## Documentation Scripts

| Script | Purpose |
|---|---|
| `build-docs-html.sh` | Builds consolidated docs HTML artifact |
| `render-docs-html.py` | Internal markdown-to-HTML renderer |
| `visualize-bitbake-log.py` | Parses cooker logs into task/recipe/stage CSV + HTML dashboard and optionally renders dependency DOT files to SVG |

## GitHub Automation Scripts

| Script | Purpose |
|---|---|
| `github/create-repo.sh` | Creates and initializes a GitHub repository |
| `github/set-secrets.sh` | Pushes required secrets to GitHub Actions |
| `github/run-workflow-once.sh` | Triggers the Yocto build workflow once and watches run status |
| `github/install-gh-from-github.sh` | Installs `gh` from official release artifacts with checksum validation |

## Shared Libraries

| Script | Purpose |
|---|---|
| `lib/host-requirements.sh` | Single source for host package list, required commands, and UTF-8 locale helpers |
| `github/lib-gh.sh` | Shared `gh` CLI discovery and authentication checks for GitHub automation scripts |

## Cloud Placeholder

| Script | Purpose |
|---|---|
| `cloud/aws-spot-build-placeholder.sh` | Placeholder interface for future AWS Spot worker lifecycle |

## Operational Notes

- Ensure submodules are initialized before running build scripts.
- `BOOTSTRAP_PACKAGES=false` disables package bootstrap in `local-build.sh`.
- `VISUALIZE_BUILD_LOGS=false` disables post-build cooker-log visualization in
  `local-build.sh`.
- Set `YOCTO_CENTRAL_CACHE_RSYNC=<user>@<host>:/srv/yocto-cache` to enable
  shared `downloads` and `sstate-cache` synchronization.
- `gh` is required for workflow automation and optional cache-seeding behavior.

## Quick GitHub Setup

```bash
export GH_REPO="owner/repo"
export VPS_HOST="your.vps.host"
export VPS_USER="yocto-ci"
export VPS_SSH_KEY="$(cat ~/.ssh/id_ed25519)"

./scripts/github/set-secrets.sh
./scripts/github/run-workflow-once.sh
```
