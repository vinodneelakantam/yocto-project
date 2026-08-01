# Architecture

## Intent

This project keeps GitHub as the coordination and visibility layer while Yocto
build execution happens in a controlled compute environment.

Core boundary:
- GitHub: source of truth, workflow orchestration, logs, and artifacts.
- Build compute: containerized Yocto toolchain, reusable scripts, cached outputs.

## Current State (Implemented)

- Primary build path runs through `.github/workflows/remote-yocto-build.yml`.
- Yocto toolchain is baked into `ghcr.io/<owner>/yocto-build-env`.
- Build execution uses `scripts/remote-build.sh` and stages outputs in `out/`.
- Local wrapper `scripts/local-build.sh` provides the same build contract for developer machines.
- Yocto cache reuse exists for `downloads` and `sstate-cache`.
- SDV application has a separate fast CI loop through `.github/workflows/bazel-sdv-app.yml`.

## Planned State (Roadmap)

- Expand compute backends to cloud spot workers with lifecycle automation.
- Add fallback behavior for worker interruption or capacity shortage.
- Add signing, verification, and release promotion checkpoints.
- Mature OTA lifecycle documentation into enforceable release gates.

## Build Flow

Primary remote flow:

1. Workflow trigger (push or manual dispatch).
2. Runner preparation (disk cleanup, cache restore, submodule sync).
3. Containerized Yocto build execution.
4. Cache save and artifact upload.
5. Build summary publication.

Optional local flow:

1. Run [scripts/local-build.sh](../scripts/local-build.sh).
2. Wrapper validates host tools and runs [scripts/remote-build.sh](../scripts/remote-build.sh).
3. Outputs are staged in [out/](../out/).

## Caching Model

The platform currently uses three cache layers:
- Container layers for build-image rebuild speed.
- Yocto source downloads cache.
- Yocto sstate cache.

Optional central rsync cache can be enabled for local/Codespace reuse through
`YOCTO_CENTRAL_CACHE_RSYNC`.

## Risks And Failure Domains

- Build image not published: remote workflow cannot start containerized build.
- Missing submodules: build fails before BitBake startup.
- Runner disk pressure: larger images may still exceed available space.
- Cache incompatibility after major toolchain change: requires key bump or clean rebuild.
- Optional self-hosted runner unavailable: opt-in jobs remain queued.

## Diagram References

See `docs/diagram-gallery.md` for all visuals with inline previews.
For a unified contributor workflow, also see `docs/contributor-journey.md`.

Primary diagram assets:
- `docs/diagrams/architecture-overview.png`
- `docs/diagrams/ci-remote-pipeline.png`
- `docs/diagrams/ghcr-image-lifecycle.png`
- `docs/diagrams/cache-layers.png`
- `docs/diagrams/repo-collaboration-block-diagram-v3.png`
