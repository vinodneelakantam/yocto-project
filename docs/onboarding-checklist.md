# Contributor Onboarding Checklist

Use this checklist for first access and first successful build. Operational
command details live in `docs/local-build.md`.

## 1. Clone And Validate Sources

- Clone with submodules:

```bash
git clone --recurse-submodules <repo-url>
cd <repo>
```

- Verify submodule content:

```bash
git submodule update --init --recursive
```

- Confirm required paths exist:
  - `sources/poky/oe-init-build-env`
  - `sources/meta-openembedded`

## 2. Prepare Tooling

- Required: `git`, `bash`, `ssh`, `rsync`
- Optional but recommended: `gh` (`gh auth login`)

## 3. Configure CI Secrets (Remote Build)

Minimum repository secrets:
- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`

Optional:
- `VPS_PORT`
- `VPS_BUILD_ROOT`

## 4. Run First Build

Choose one path:
- Local: run `./scripts/local-build.sh core-image-minimal false`
- CI: trigger Remote Yocto Build workflow (push to main or manual dispatch)

Recommended first CI inputs:
- `image=core-image-minimal`
- `clean=false`
- `backend=vps`

## 5. Verify Evidence

- Workflow summary shows image, backend, and revision.
- Build artifact is present.
- `out/build-summary.txt` reports successful task completion.

## 6. Recovery Shortlist

- Missing submodules: rerun recursive submodule initialization.
- SSH failure: recheck `VPS_*` secrets and key validity.
- Missing artifact: inspect workflow logs around build and upload steps.
