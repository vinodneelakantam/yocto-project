# Scripts

- `remote-build.sh`: Runs BitBake on remote compute and stages outputs in `out/`
- `bootstrap-worker-packages.sh`: Installs required Yocto build dependencies on Debian/Ubuntu workers
- `generate-build-metadata.sh`: Writes reproducibility metadata (commit, submodules, image digests) into `out/metadata/`
- `qemu-smoke-test.sh`: Runs a QEMU smoke-test lane (or marks skipped) and writes results into `out/smoke-tests/`
- `security/generate-compliance-report.sh`: Generates SBOM/license/CVE summary artifacts into `out/compliance/`
- `security/cve-gate.sh`: Release gate that fails promotion on high/critical CVE status or missing CVE summary
- `github/create-repo.sh`: Creates a GitHub repo from this directory and pushes it
- `github/set-secrets.sh`: Configures required GitHub Actions secrets via `gh`
- `github/run-workflow-once.sh`: Triggers `remote-yocto-build.yml` once and watches it
- `github/promote-artifact.sh`: Downloads a build artifact from a source run and repackages it for environment promotion
- `github/install-gh-from-github.sh`: Downloads `gh` from official GitHub Releases into `.tmp/`, verifies checksum, and installs to `.local/bin/gh`
- `cloud/aws-spot-build-placeholder.sh`: Placeholder interface for future AWS Spot worker lifecycle automation

## Notes

- Script expects `sources/poky/oe-init-build-env` on VPS
- Ensure submodules are initialized before running remote builds
- Use GitHub Actions workflow to call this script over SSH
- If `gh` is not installed system-wide, scripts auto-bootstrap it from GitHub release packages
- Worker package bootstrap can be disabled with `BOOTSTRAP_PACKAGES=false`
- Worker bootstrap installs `zstd`, which provides `pzstd` required by Yocto HOSTTOOLS
- To share cache across local, Codespaces, and VPS builds, set `YOCTO_CENTRAL_CACHE_RSYNC=<user>@<host>:/srv/yocto-cache`
- `scripts/remote-build.sh` will pull and push `downloads` and `sstate-cache` to that central cache endpoint

## GitHub Setup Automation

Export values, then run:

```bash
export GH_REPO="owner/repo"
export VPS_HOST="your.vps.host"
export VPS_USER="yocto-ci"
export VPS_SSH_KEY="$(cat ~/.ssh/id_ed25519)"
export VPS_PORT="22"                 # optional
export VPS_BUILD_ROOT="~/yocto-project" # optional

./scripts/github/set-secrets.sh
./scripts/github/run-workflow-once.sh
```

If you do not have a repo yet:

```bash
export GH_REPO_NAME="yocto-project"
export GH_VISIBILITY="public"
./scripts/github/create-repo.sh
```
