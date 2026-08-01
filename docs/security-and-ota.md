# Security And OTA

This document separates what is already enforced in the repository from what is
planned for upcoming releases.

## Current Security Posture

- No private signing keys are stored in the repository.
- Build artifacts and logs are centralized through GitHub workflows.
- Submodules pin upstream source revisions for traceability.
- Build scripts support reproducible execution through containerized tooling and
	deterministic output staging.
- Every build produces an SPDX SBOM (`create-spdx`, enabled by default) and is
	converted to CycloneDX; CVE scanning (`cve-check`) is opt-in per build and
	enforced as a release gate in CI. See `docs/sbom-and-cve-workflow.md`.

## Security Controls Planned Next

- Add signing pipeline for release artifacts in a controlled signing environment.
- Publish checksums/signatures alongside release assets.
- Add verification steps before promotion/deployment.
- Define secret rotation and emergency revocation runbook.

## OTA Direction

- Target A/B update strategy with health-check-based rollback.
- Require integrity validation before activation switch.
- Attach release provenance and SBOM data to OTA payload lineage.
- Define promotion gates (candidate -> verified -> production).

## Hardening Baseline

- Minimize image package surface and disable unused services.
- Enforce least-privilege runtime defaults.
- Enable compatible kernel hardening options.
- Add recurring vulnerability scan checkpoints in release workflow.

## Evidence And Ownership

- Architecture context: `docs/architecture.md`
- Cloud worker roadmap dependencies: `docs/cloud/aws-spot-worker-plan.md`
- Backlog tracker for remaining controls: `docs/archive/jira-development-backlog.md`
