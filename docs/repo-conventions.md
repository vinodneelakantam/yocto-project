# Repository Conventions

## Purpose

This repository is the single control plane for Yocto recipes/apps and build visibility. Heavy build execution happens on external workers.

## Ownership By Path

- layers/: Product recipes, app integration, and layer metadata.
- conf/: Reusable configuration templates.
- scripts/: Build automation and helper tooling.
- .github/workflows/: CI orchestration and artifact publication.
- docs/: Architecture, security, onboarding, and operational guidance.
- sources/: Pinned upstream submodules only.

## Naming Rules

- New layer directories use: meta-<domain>.
- New recipes use lowercase names and standard Yocto layout.
- New automation scripts use kebab-case and include a short README note.
- Diagram/source docs use descriptive suffixes with version only when replacing an old variant.
- Release branches use `release/<version>`.
- Hotfix branches use `hotfix/<version>-<topic>`.

## Change Rules

- Any workflow change must include a docs update in docs/architecture.md or README.md.
- Any new script that affects build setup must be listed in scripts/README.md.
- Submodule updates must be explicit and reviewed (no accidental pointer drift).

## Build Reproducibility Rules

- Keep upstream sources pinned by commit.
- Keep worker setup package-driven where possible.
- Reuse caches where safe (downloads/sstate) to reduce cost and rebuild time.
