# Operations Playbook

## Pipeline Stages

- PR validation: `.github/workflows/pr-validation.yml`
- Nightly full build: `.github/workflows/nightly-full-build.yml`
- Release build + compliance gate: `.github/workflows/release-build.yml`
- Artifact promotion: `.github/workflows/artifact-promotion.yml`

## SLA Targets

- PR validation feedback: under 15 minutes.
- Nightly build completion: before start of next workday.
- Release build with compliance reports: deterministic and reproducible from pinned commits.

## Triage Rotation

- Assign one weekly build sheriff.
- Sheriff reviews failed runs, classifies infra/build/recipe regressions, and posts remediation owner.
- Repeated failures require a corrective issue before next release cut.

## Release Checklist

- Confirm release branch status is green.
- Confirm `out/metadata/build-metadata.json` is present.
- Confirm SBOM, license manifest, and CVE summary are present under `out/compliance/`.
- Ensure CVE gate passes (or explicit waiver for missing CVE report).
- Run artifact promotion to `qa`, then `prod`.

## OTA Rollback Discipline

- Use A/B update model.
- Validate health checks before slot switch completion.
- Test rollback path for each release candidate before production promotion.
