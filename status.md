# Repository Status

## Summary

This repository is already functional as a Yocto build-control and SDV integration platform. The remaining work is now mostly about hardening, operationalization, and release-security readiness.

## Status by area

| Area | Status | Count / metric | Notes |
|---|---|---:|---|
| Core build capabilities | Done | 6 major capabilities | Local build, remote build, artifact staging, cache-aware build flow, image output handling, and debug/release/secure build variants (`docs/architecture.md#build-variants-debug--release--secure`) are implemented. |
| CI workflows | Done | 6 workflows | Remote Yocto build, Bazel SDV app CI, docs publishing, build-image publishing, cache seeding, and build-health reporting are present. |
| Build environment automation | Done | 3 automation layers | GHCR container, devcontainer setup, and bootstrap/sanity scripts are implemented. |
| SDV app integration | Done | 2 integration loops | Native Bazel inner loop and Yocto outer-loop packaging are both present. |
| Documentation pages | Partially done | 10+ docs | Architecture, onboarding, local build, SDV Bazel, security, diagrams, and scripts are covered, but still fragmented. |
| Security / OTA controls | In progress | 1 enforced release gate | SBOM (SPDX + CycloneDX) generation and a CVE-severity release gate are now enforced (`docs/sbom-and-cve-workflow.md`). Signing, verification, provenance, rollback, and promotion gates remain roadmap items. |
| Multi-backend worker support | In progress | 1 implemented backend + 2 planned | GitHub-hosted/remote flow exists; Codespace and cloud spot backends are only partially operationalized. |
| Operational runbook coverage | To do | 0 full runbooks | There is no single end-to-end troubleshooting and recovery guide yet. |

## Implementation backlog with Jira-style IDs

| Jira ID | Work item | Priority | Estimated effort | Suggested size | Outcome |
|---|---|---|---:|---:|---|
| YP-101 | Consolidate documentation into one contributor journey | High | 5-7 person-days | Medium | One onboarding path, one build guide, one operations guide, and one security/OTA page. |
| YP-102 | Add a full operational runbook | High | 4-6 person-days | Medium | Build failure triage, cache recovery, artifact validation, and rollback instructions. |
| YP-103 | Implement release-signing and verification gates | High | 7-10 person-days | Large | Signed artifacts, checksum verification, release promotion checks, and provenance metadata. |
| YP-104 | Complete cloud worker lifecycle automation | Medium | 8-12 person-days | Large | Worker provisioning, health checks, failover, and teardown automation. |
| YP-105 | Harden cache policies and observability | Medium | 3-5 person-days | Medium | Better cache hit reporting, policy docs, and cache maintenance playbooks. |
| YP-106 | Expand SDV app packaging examples | Medium | 3-4 person-days | Medium | More realistic packaging and test examples for larger future app growth. |

## Suggested implementation sequence

1. YP-101: Documentation consolidation — 5-7 days
2. YP-102: Operational runbook — 4-6 days
3. YP-103: Security/OTA gates — 7-10 days
4. YP-104: Backend automation — 8-12 days
5. YP-105 and YP-106: Cache hardening and packaging examples — 3-5 days each

## Prompt-ready checklist

- 6 CI/workflow assets already exist
- 5 core build capabilities already exist
- 4 major remaining implementation themes
- 6 backlog items with Jira-style IDs
- 3 high-value first milestones for future implementation
