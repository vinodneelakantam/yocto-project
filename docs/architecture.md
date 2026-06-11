# Architecture

## High-Level Intent

This project separates coordination from compute:

- Coordination happens in GitHub (code, workflow control, visibility).
- Compute happens on external workers (VPS, AWS Spot, or similar) for Yocto/BitBake execution.

For a visual summary, see:
- `docs/diagrams/repo-collaboration-block-diagram-v3.png`
- `docs/diagrams/repo-collaboration-block-diagram-v3.dot`

## Model

- GitHub: source of truth, CI orchestration, logs, and artifacts
- External compute workers: Yocto build execution environment (ephemeral or persistent)
- Repository: stores layer metadata, scripts, docs, and workflow definitions

## Collaboration View

1. Developers collaborate through this repository (commits and workflow dispatch).
2. GitHub Actions orchestrates remote build steps.
3. External worker performs the actual Yocto build using repo content and submodules.
4. Artifacts return to GitHub for shared visibility and download.

## Build Data Flow

1. Push to `main` triggers GitHub Actions workflow.
2. Workflow syncs/bootstrap repository on external compute.
3. Worker executes `scripts/remote-build.sh`.
4. Output is staged in `out/` on worker.
5. Artifacts are copied to GitHub runner and uploaded.

## Build Responsibility Split

- GitHub Actions responsibility:
	- Trigger handling, orchestration, artifact publishing, and visibility.
- Worker responsibility:
	- Repo checkout/bootstrap, package/tool installation, cache usage, BitBake execution, output generation.

## Cost And Scale Strategy

- Keep GitHub as the frontend for status, logs, and build outputs.
- Use cloud spot instances (for example AWS Spot) when always-on machines are unnecessary.
- Treat workers as disposable to reduce baseline cost.
- Use package-based dependency setup and build caches to keep worker startup and rebuild time low.

## Why This Model

- Avoids GitHub-hosted runner disk/CPU constraints for Yocto
- Preserves portfolio visibility via Actions logs and artifacts
- Separates orchestration from compute for scalability

## Failure Domains

- Worker provisioning/connectivity failures (VPS/cloud instance lifecycle)
- Missing source submodules (`sources/poky`, `sources/meta-openembedded`) on worker
- Missing Yocto setup script (`sources/poky/oe-init-build-env`) on worker
- Build resource limits on worker (RAM/storage)
- Artifact transfer issues (scp/rsync)
