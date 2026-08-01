# Resume Gap Roadmap

## Purpose

[Resume.md](../Resume.md) sets the target capability set for this portfolio project.
This page tracks the gaps between that target and the current repository state,
in priority order, with concrete files and implementation steps for each item.
Continues the backlog numbering started in [status.md](../status.md) (YP-101..YP-106).

## Priority Summary

| Jira ID | Gap | Priority | Effort | Depends on |
|---|---|---|---:|---|
| YP-107 | SBOM generation + CVE triage workflow | Done | 6-9 days | - |
| YP-108 | End-to-end signed OTA/SOTA with rollback | P0 | 10-14 days | YP-107 (SBOM attaches to release) |
| YP-109 | Multi-variant builds (debug/release/secure) | Done | 5-8 days | - |
| YP-110 | Automotive cybersecurity evidence (TARA, ISO/SAE 21434, CSMS/SUMS) | P1 | 8-12 days | YP-107, YP-108 |
| YP-111 | QEMU smoke/regression + protocol validation tests | P1 | 6-10 days | YP-109 |
| YP-112 | ASPICE SWE.5 governance artifacts | P2 | 5-7 days | YP-109, YP-111 |
| YP-113 | Jenkins / Kubernetes / Artifactory pipeline breadth | P3 | 8-12 days | YP-108 |

Suggested order: YP-107 → YP-109 → YP-108 → YP-111 → YP-110 → YP-112 → YP-113.
(Multi-variant builds are pulled forward because OTA and testing both need
variant-aware artifacts to work against.)

---

## YP-107: SBOM generation + CVE triage workflow

**Status: Done.** Implemented as:
- [scripts/sbom/spdx-to-cyclonedx.py](../scripts/sbom/spdx-to-cyclonedx.py) — converts the Yocto `create-spdx` bundle (already enabled by default) to CycloneDX 1.5.
- [scripts/sbom/triage-cves.py](../scripts/sbom/triage-cves.py) + [scripts/sbom/cve-waivers.json](../scripts/sbom/cve-waivers.json) — gates on unwaived CVEs at/above a severity threshold.
- [scripts/sbom/generate-sbom-report.sh](../scripts/sbom/generate-sbom-report.sh) — orchestrates both from a completed build's output.
- `ENABLE_CVE_CHECK=true` support in [scripts/remote-build.sh](../scripts/remote-build.sh) to opt into `cve-check`.
- [.github/workflows/sbom-scan.yml](../.github/workflows/sbom-scan.yml) — runs after `Yocto Build` completes, gates the run on unwaived CVEs.

Full write-up: [docs/sbom-and-cve-workflow.md](sbom-and-cve-workflow.md).

**Original goal:** Every release image ships with an SPDX and CycloneDX SBOM, and CI fails
or flags builds on unresolved high/critical CVEs.

**Files to add:**
- `.github/workflows/sbom-scan.yml` — runs after image build, generates SBOM, runs SCA scan.
- `scripts/sbom/generate-sbom.sh` — wraps BitBake's `create-spdx` (poky already supports `INHERIT += "create-spdx"`) and converts/aggregates to CycloneDX.
- `scripts/sbom/scan-cves.sh` — runs `cve-check` (`INHERIT += "cve-check"` in poky) or Grype/Trivy against the SBOM.
- `docs/sbom-and-cve-workflow.md` — documents the pipeline, triage process, and exception/waiver process.

**Steps:**
1. Enable `INHERIT += "create-spdx"` in `conf/local.conf.example` and the build distro conf; confirm `tmp/deploy/spdx/` output.
2. Enable `INHERIT += "cve-check"` and set `CVE_CHECK_LOG`/`CVE_CHECK_SUMMARY_DIR`.
3. Add a CI step to convert manifest/SPDX output to CycloneDX (e.g. via `cyclonedx-py` or `spdx-to-cyclonedx`).
4. Publish SBOM + CVE summary as workflow artifacts and a build-summary table (reuse the pattern in [.github/workflows/build-health-dashboard.yml](../.github/workflows/build-health-dashboard.yml)).
5. Define a triage policy: block release on unwaived critical/high CVEs, require a documented waiver file (`docs/sbom/cve-waivers.md`) for accepted risk.
6. Update [docs/security-and-ota.md](security-and-ota.md) "Security Controls Planned Next" to move this item to "Current."

**Definition of done:** a build run produces an SPDX file, a CycloneDX file, and a CVE report artifact, and the workflow demonstrably fails on an injected critical CVE test fixture.

---

## YP-108: End-to-end signed OTA/SOTA with rollback

**Goal:** Replace the current `meta-ota` policy stub with a working signed update
path and a demonstrable rollback.

**Files to add/change:**
- `layers/meta-ota/recipes-ota/rauc/` (or `swupdate`) — integrate an actual update agent (RAUC recommended for A/B + bootloader integration).
- `layers/meta-ota/recipes-ota/rauc/files/system.conf` — slot/bundle definition for A/B.
- `scripts/ota/generate-keys.sh` — generates dev signing keypair (never commit private key; store path convention only).
- `scripts/ota/sign-bundle.sh` — signs the `.raucb` bundle.
- `scripts/ota/verify-and-install.sh` — verifies signature + installs to inactive slot.
- `.github/workflows/ota-release.yml` — builds image, builds bundle, signs it (using a GitHub Actions secret-backed key), publishes bundle + signature + SBOM reference together.
- `docs/security-and-ota.md` — update with the concrete design once implemented.

**Steps:**
1. Add RAUC recipe/class to `meta-ota`, define two rootfs slots in the image (wic partition layout change in `conf/`).
2. Generate a dev-only signing keypair; wire the public cert into the image and keep the private key only as a CI secret (`OTA_SIGNING_KEY`), never in the repo.
3. Build `.raucb` bundles in CI, sign them, and publish signature + checksum alongside the bundle.
4. Add a QEMU-based rollback test: install a bundle with an intentionally broken health check, confirm automatic rollback to slot A (ties into YP-111).
5. Document promotion gates: candidate → verified (signature + CVE clean) → production, per [docs/security-and-ota.md](security-and-ota.md).

**Definition of done:** a QEMU machine boots slot A, installs a signed update to slot B, switches, and rolls back automatically when the new slot fails a health check — captured as a CI job log/artifact.

---

## YP-109: Multi-variant builds (debug/release/secure)

**Status: Done.** Implemented as:
- [layers/meta-portfolio/conf/distro/portfolio-debug.conf](../layers/meta-portfolio/conf/distro/portfolio-debug.conf), `portfolio-release.conf`, `portfolio-secure.conf` (`secure` requires `release`) — validated with `bitbake-getvar` against a live build tree (DISTRO, IMAGE_FEATURES, INHIBIT_PACKAGE_STRIP, DISTRO_FEATURES, IMAGE_INSTALL all resolve as designed).
- `BUILD_VARIANT` env var support in [scripts/remote-build.sh](../scripts/remote-build.sh) — validates `debug`/`release`/`secure`, overrides `DISTRO`, namespaces output under `out/<variant>/`; unset preserves prior single-variant behavior. Propagates to [scripts/local-build.sh](../scripts/local-build.sh) automatically (it calls `remote-build.sh`); a log line surfaces the active variant.
- Opt-in `variant-matrix-build` job in [.github/workflows/remote-yocto-build.yml](../.github/workflows/remote-yocto-build.yml) (manual dispatch, `build_all_variants: true`) — matrix over the three variants, per-variant sstate cache keys, per-variant artifact upload.
- Feature comparison table and usage documented in [docs/architecture.md](architecture.md#build-variants-debug--release--secure).

**Original goal:** One recipe/config set producing three clearly differentiated image variants.

**Files to add:**
- `conf/distro/*-debug.conf`, `*-release.conf`, `*-secure.conf` (or `DISTRO_FEATURES`/`IMAGE_FEATURES` overlays keyed by a `BUILD_VARIANT` variable).
- `layers/meta-portfolio/conf/distro/include/variant-debug.inc`, `variant-release.inc`, `variant-secure.inc`.
- `.github/workflows/remote-yocto-build.yml` — add a matrix over variants.

**Steps:**
1. Define variant differences explicitly: debug = dbg-pkgs + ptest + root shell; release = stripped, minimal packages, no debug tools; secure = release baseline + read-only rootfs, dm-verity/secure boot hooks, no interactive shell.
2. Add a `BUILD_VARIANT` input to [scripts/local-build.sh](../scripts/local-build.sh) and [scripts/remote-build.sh](../scripts/remote-build.sh).
3. Add a CI matrix job so all three variants build and publish artifacts under `out/<variant>/`.
4. Document variant differences in [docs/architecture.md](architecture.md).

**Definition of done:** CI produces three distinctly named image artifacts per run, and the docs table shows the feature delta between them.

---

## YP-110: Automotive cybersecurity evidence (TARA, ISO/SAE 21434, CSMS/SUMS)

**Goal:** A documentation package that reads like real automotive security evidence, not just prose.

**Files to add:**
- `docs/compliance/tara.md` — asset list, threat scenarios, attack feasibility rating, risk treatment decisions for this platform.
- `docs/compliance/iso-21434-mapping.md` — table mapping ISO/SAE 21434 clauses (e.g. concept phase, TARA, cybersecurity requirements, verification/validation, incident response) to concrete repo artifacts (this roadmap, SBOM workflow, OTA workflow, test reports).
- `docs/compliance/csms-evidence.md` — CSMS process evidence: how vulnerabilities are monitored (link to YP-107 CVE workflow) and triaged.
- `docs/compliance/sums-evidence.md` — SUMS process evidence: how updates are managed (link to YP-108 OTA workflow), version tracking, rollback proof.

**Steps:**
1. Base the TARA on the actual system: image build pipeline, OTA channel, CAN/network exposure surface for the SDV app.
2. Map each ISO/SAE 21434 clause to a real artifact link — do not invent unverifiable claims; where a control is only partial, say so explicitly (matches current repo convention of separating "current" vs "planned").
3. Cross-link from [docs/security-and-ota.md](security-and-ota.md) and the root [README.md](../README.md) documentation map.

**Definition of done:** each ISO/SAE 21434 clause row links to a real file/workflow in this repo, not a placeholder.

---

## YP-111: QEMU smoke/regression + protocol validation tests

**Goal:** Automated tests that boot the built image and validate behavior, including simulated bus protocols.

**Files to add:**
- `test/smoke/boot-qemu.sh` — boots the image under `runqemu`, waits for login prompt, checks core services.
- `test/regression/` — scripted checks against known-good baselines (package list diff, boot-time budget).
- `test/protocols/can-loopback-test.sh` — uses `vcan` (virtual CAN) inside QEMU to validate CAN send/receive for the SDV app.
- `test/protocols/uart-echo-test.sh`, `test/protocols/i2c-mock-test.sh` — simulated bus validation using QEMU device models or mocked interfaces.
- `.github/workflows/qemu-validation.yml` — runs the above on every build.

**Steps:**
1. Start with boot smoke test (login prompt + systemd `is-system-running`).
2. Add `vcan0` setup inside the QEMU test harness, exercise the SDV app's CAN path (`apps/sdv-vehicle-service`) end-to-end.
3. Add regression baseline snapshots (package manifest, image size, boot time) and fail CI on unexplained drift.
4. Feed results into the OTA rollback test from YP-108 (failed health check → rollback).

**Definition of done:** CI job boots the image in QEMU, sends/receives a CAN frame through the SDV service, and reports pass/fail as a workflow status check.

---

## YP-112: ASPICE SWE.5 governance artifacts

**Goal:** Traceable integration/release governance in the style ASPICE assessors expect.

**Files to add:**
- `docs/compliance/aspice-swe5-trace.md` — traceability matrix: requirement → implementation (recipe/workflow) → test (YP-111) → release record.
- `docs/compliance/release-checklist.md` — the actual gate checklist a release must pass (build variant, SBOM clean, CVE triage complete, OTA signed, tests green).
- `docs/compliance/change-log-template.md` — structured release/change record template.

**Steps:**
1. Define 5-10 representative "requirements" for this portfolio project (e.g. "image must boot under QEMU in <60s", "no unwaived critical CVEs").
2. Trace each to the CI job/test that verifies it (link YP-107/YP-108/YP-111 artifacts).
3. Use the release checklist as a required PR template section for any change touching `layers/`, `conf/`, or release workflows.

**Definition of done:** one worked example release with the checklist filled out and every row linked to a real CI run.

---

## YP-113: Jenkins / Kubernetes / Artifactory pipeline breadth

**Goal:** Show the broader enterprise CI/CD stack referenced in the resume, without abandoning the working GitHub Actions path.

**Files to add:**
- `ci/jenkins/Jenkinsfile` — mirrors the remote build workflow as a Jenkins declarative pipeline (can target the same container image).
- `ci/k8s/build-job.yaml` — Kubernetes `Job` manifest running the same containerized build for a self-hosted/cluster scenario.
- `scripts/artifactory/publish-artifact.sh` — pushes signed release artifacts + SBOM to an Artifactory (or Artifactory-compatible, e.g. a generic OCI/Nexus) repository.
- `docs/cicd-pipeline-architecture.md` — explains how GitHub Actions, Jenkins, and Kubernetes relate (which is primary, which is illustrative).

**Steps:**
1. Keep GitHub Actions as the primary, working pipeline (per existing repo non-goals of not requiring always-on infrastructure).
2. Add Jenkinsfile as a parallel, runnable-on-demand pipeline definition using the same `scripts/remote-build.sh` contract, so it is not duplicated logic.
3. Add the Kubernetes Job manifest as the containerized execution target Jenkins or Actions could delegate to.
4. Add the Artifactory publish script as an optional step invoked after YP-108's signed bundle is produced.

**Definition of done:** Jenkinsfile and k8s Job manifest exist, reference the same build script contract, and are documented as an alternate/enterprise execution path.

---

## Cross-references

- Current vs planned security posture: [docs/security-and-ota.md](security-and-ota.md)
- Architecture and build flow: [docs/architecture.md](architecture.md)
- Existing operational backlog: [status.md](../status.md)
- Design rationale: [docs/repository-deep-dive.md](repository-deep-dive.md)
