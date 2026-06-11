# Contributor Onboarding Checklist

## Access And Tooling

- Clone with submodules:
  - git clone --recurse-submodules <repo-url>
- Ensure required tools:
  - git, bash, rsync, ssh
- Optional GitHub CLI tools:
  - gh auth login

## First-Time Repository Validation

- Validate submodules:
  - git submodule update --init --recursive
- Confirm required paths exist:
  - sources/poky/oe-init-build-env
  - sources/meta-openembedded

## Remote Build Configuration

Set repository secrets (minimum):

- VPS_HOST
- VPS_USER
- VPS_SSH_KEY

Optional:

- VPS_PORT
- VPS_BUILD_ROOT

## Trigger First Build

- Push to main, or
- Use GitHub Actions manual trigger for Remote Yocto Build.

Recommended initial inputs:

- image: core-image-minimal
- clean: false
- backend: vps

## Validate Build Evidence

In GitHub Actions run page:

- Confirm workflow summary includes image, backend, and revision.
- Confirm artifact exists: yocto-images-<run_number>.
- Download artifact and review out/build-summary.txt.

## Common Recovery Steps

- Missing submodules: run recursive submodule init/update.
- SSH failures: re-check VPS_* secrets and key permissions.
- Missing artifacts: inspect remote-build.sh logs and build summary.
