# Scripts

- `remote-build.sh`: Runs BitBake on remote compute and stages outputs in `out/`
- `github/create-repo.sh`: Creates a GitHub repo from this directory and pushes it
- `github/set-secrets.sh`: Configures required GitHub Actions secrets via `gh`
- `github/run-workflow-once.sh`: Triggers `remote-yocto-build.yml` once and watches it

## Notes

- Script expects `oe-init-build-env` at repo root on VPS
- Use GitHub Actions workflow to call this script over SSH

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

If you do not have a repo yet:

```bash
export GH_REPO_NAME="yocto-project"
export GH_VISIBILITY="public"
./scripts/github/create-repo.sh
```
```
