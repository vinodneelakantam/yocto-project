# Yocto GitHub-Centric Build Project

GitHub-first Yocto build orchestration with a reproducible container build
environment and an SDV app workflow.

## Detailed Docs (GitHub Pages)

- Main docs site: https://vinodneelakantam.github.io/yocto-project/
- Fork/template pattern: https://<owner>.github.io/<repo>/
- Preserved deep-dive content moved from root README: `docs/repository-deep-dive.md`

Use this README as a quick index. Full architecture and operational guidance is
in GitHub Pages.

## Repository Scope

- `apps/`: Bazel-built SDV app
- `layers/`: Project Yocto layers
- `sources/`: Pinned upstream submodules (`poky`, `meta-openembedded`)
- `conf/`: Example Yocto config templates
- `scripts/`: Build and GitHub automation scripts
- `docs/`: Source markdown for the published documentation site

## Core Workflows

| Workflow | File | Purpose |
|---|---|---|
| Yocto Build | `.github/workflows/remote-yocto-build.yml` | Main Yocto image build path. |
| Publish Yocto Build Image | `.github/workflows/publish-build-image.yml` | Rebuilds and publishes GHCR build image. |
| Bazel SDV App | `.github/workflows/bazel-sdv-app.yml` | Fast C/C++/Python app build and test. |
| Docs HTML | `.github/workflows/docs-html.yml` | Builds docs HTML artifact. |
| Docs Pages Deploy | `.github/workflows/docs-pages.yml` | Publishes docs to GitHub Pages. |
| Build Health Dashboard | `.github/workflows/build-health-dashboard.yml` | CI health summary in Actions job summary. |

## Quick Start

1. Clone with submodules.

```bash
git clone --recurse-submodules https://github.com/<owner>/<repo>.git
cd <repo>
```

2. Build docs locally.

```bash
./scripts/build-docs-html.sh
```

3. Run SDV app tests.

```bash
bazel test //apps/sdv-vehicle-service/...
```

4. Trigger Yocto build from Actions (push to `main` or manual dispatch).

## Important Links

- Diagram gallery: `docs/diagram-gallery.md`
- Repository deep-dive (migrated content): `docs/repository-deep-dive.md`
- Local build notes: `docs/local-build.md`
- Architecture: `docs/architecture.md`
- Security and OTA: `docs/security-and-ota.md`
- SDV Bazel integration: `docs/sdv-bazel-app.md`
