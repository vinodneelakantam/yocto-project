# Contributor Journey

This page is the single starting point for contributors working in this repository.
It connects the repository overview, day-one setup, local build workflow, CI workflow,
and the key documents that explain each subsystem in more detail.

## 1. What this repository is

This repository acts as the control plane for a Yocto-based build platform with an
embedded Software-Defined-Vehicle (SDV) application example.

It currently supports:
- Yocto image builds from local machines and GitHub Actions
- A Bazel-based inner loop for the SDV app
- Yocto packaging of that app into the target image
- Build artifact generation and simple build metrics reporting

## 2. Fast path for a new contributor

### Clone and initialize

```bash
git clone --recurse-submodules <repo-url>
cd <repo>
git submodule update --init --recursive
```

### First local build

```bash
./scripts/local-build.sh core-image-minimal false
```

This wrapper will:
- initialize submodules,
- install host packages when enabled,
- run the Yocto build,
- generate build artifacts,
- and stage outputs under the repository's out/ directory.

### First Bazel check for the SDV app

```bash
bazel test //apps/sdv-vehicle-service/...
```

## 3. Main workflows

### A. Local Yocto workflow

Use this when you want to produce a full image locally.

Primary entrypoints:
- [scripts/local-build.sh](../scripts/local-build.sh)
- [scripts/remote-build.sh](../scripts/remote-build.sh)

Typical command:

```bash
./scripts/local-build.sh core-image-minimal false
```

Expected outputs:
- [out/](../out/)
- [out/build-summary.txt](../out/build-summary.txt)
- image artifacts under out/images when available

### B. CI Yocto workflow

The repository also includes GitHub Actions workflows for remote execution.

Relevant workflow:
- [.github/workflows/remote-yocto-build.yml](../.github/workflows/remote-yocto-build.yml)

This workflow is the default remote build path for the repository and uses cached
downloads and sstate data to reduce rebuild time.

### C. Bazel inner loop for the SDV app

Use this for fast app-level feedback.

Relevant app docs:
- [apps/sdv-vehicle-service/README.md](../apps/sdv-vehicle-service/README.md)
- [docs/sdv-bazel-app.md](./sdv-bazel-app.md)

Typical commands:

```bash
bazel build //apps/sdv-vehicle-service/...
bazel test //apps/sdv-vehicle-service/...
```

### D. Build analysis and visualization

After a successful build, the repository can generate extra analysis artifacts.

Relevant script:
- [scripts/generate-bitbake-artifacts.sh](../scripts/generate-bitbake-artifacts.sh)

This produces:
- task dependency graphs,
- cooker-log visualization outputs,
- and summary CSV/HTML artifacts.

## 4. Repository map

Use this map to jump to the right doc quickly.

| If you need... | Read |
|---|---|
| Repository overview and quick start | [README.md](../README.md) |
| This contributor journey | [docs/contributor-journey.md](./contributor-journey.md) |
| Architecture and roadmap boundaries | [docs/architecture.md](./architecture.md) |
| Local build instructions | [docs/local-build.md](./local-build.md) |
| Onboarding checklist | [docs/onboarding-checklist.md](./onboarding-checklist.md) |
| SDV Bazel + Yocto integration | [docs/sdv-bazel-app.md](./sdv-bazel-app.md) |
| Security and OTA posture | [docs/security-and-ota.md](./security-and-ota.md) |
| Scripts inventory | [scripts/README.md](../scripts/README.md) |

## 5. Common troubleshooting

### Missing submodules

```bash
git submodule update --init --recursive
```

### Host dependency problems

```bash
./scripts/bootstrap-worker-packages.sh
```

### Build artifact missing

Check:
- [out/](../out/)
- [out/build-summary.txt](../out/build-summary.txt)
- workflow logs for the relevant GitHub Actions run

## 6. Suggested next steps

1. Run the local build once end to end.
2. Review the generated artifacts under out/.
3. Try the Bazel inner loop for the SDV app.
4. Read the SDV integration doc when you are ready to package or extend the app.
