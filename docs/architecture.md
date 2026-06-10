# Architecture

## Model

- GitHub: source of truth, CI orchestration, logs, and artifacts
- VPS: Yocto build execution environment
- Repository: stores layer metadata, scripts, docs, and workflow definitions

## Build Data Flow

1. Push to `main` triggers GitHub Actions workflow.
2. Workflow syncs repository to VPS.
3. VPS executes `scripts/remote-build.sh`.
4. Output is staged in `out/` on VPS.
5. Artifacts are copied to GitHub runner and uploaded.

## Why This Model

- Avoids GitHub-hosted runner disk/CPU constraints for Yocto
- Preserves portfolio visibility via Actions logs and artifacts
- Separates orchestration from compute for scalability

## Failure Domains

- SSH connectivity to VPS
- Missing Yocto setup (`oe-init-build-env`) on remote host
- Build resource limits on VPS (RAM/storage)
- Artifact transfer issues (scp/rsync)
