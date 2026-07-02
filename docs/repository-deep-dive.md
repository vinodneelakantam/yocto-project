# Repository Deep Dive

This page captures design rationale that is intentionally not repeated in the
root README.

For current architecture and status, see `docs/architecture.md`.
For day-to-day commands, see `docs/local-build.md` and `docs/onboarding-checklist.md`.

## Why This Repository Exists

The repository provides one place for:
- build orchestration logic,
- Yocto layer ownership,
- reproducible build environment control,
- artifact visibility through GitHub.

It is optimized for teams that need Yocto traceability without forcing all
contributors to run heavy builds on their personal machines.

## Key Design Decisions

### 1) Pinned upstream as submodules

Upstream Yocto projects are tracked as submodules instead of copied into this
repository.

Why:
- preserves provenance and update intent,
- keeps project history focused on owned layers/scripts,
- allows controlled upgrade cadence.

### 2) Containerized build toolchain

Build tooling is versioned in a GHCR image and consumed by CI and local flows.

Why:
- reduces host drift,
- avoids repeated package installation in CI,
- keeps local and CI toolchains aligned.

### 3) Scripted build contract

`scripts/remote-build.sh` is the core build contract. Wrappers and workflows
call into this instead of duplicating build logic.

Why:
- one implementation path for outputs and summary format,
- easier debugging and change control,
- clearer future migration to additional compute backends.

### 4) Fast inner loop + reproducible outer loop

The SDV app uses Bazel for rapid native iteration and is also packaged via
Yocto for image-level integration.

Why:
- developers keep short feedback loops,
- release artifacts still come from Yocto.

## Current Constraints

- Cloud spot worker lifecycle is documented but not fully automated.
- Signing and OTA flow are defined as roadmap controls, not enforced release gates yet.
- Cache strategy exists and works, but policy hardening is still in progress.

## Future Direction

- Complete compute-backend abstraction with spot worker lifecycle and fallback.
- Add signing and verification checkpoints into release workflow.
- Promote OTA from documentation guidance to executable release criteria.

## Related References

- `docs/architecture.md`
- `docs/security-and-ota.md`
- `docs/cloud/aws-spot-worker-plan.md`
- `docs/diagram-gallery.md`
