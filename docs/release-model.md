# Branch And Release Model

## Branch Roles

- `main`: integration branch; all PRs land here after PR validation.
- `release/<version>`: stabilization branch for a specific release train.
- `hotfix/<version>-<topic>`: urgent fixes based on current production release.

## Flow

1. Feature changes merge into `main`.
2. Release cut creates `release/<version>` from a known-good `main` commit.
3. Only release fixes are accepted on `release/*`.
4. Production incidents are fixed on `hotfix/*`, then merged back to both `release/*` and `main`.

## Build Promotion

- Build once in release workflow.
- Promote the same immutable artifact package from `dev` to `qa` to `prod` with `artifact-promotion.yml`.
- Promotion never recompiles BitBake outputs.
