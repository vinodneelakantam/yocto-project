# Yocto Image Output Artifacts

This page explains how Yocto image outputs look under `out/images/<machine>/`
in this repository, and what each file is used for.

Example folder:

- `out/images/qemux86-64/`

## Naming Pattern

Yocto usually emits two names for the same artifact:

- Timestamped filename (real artifact), for example:
  - `core-image-minimal-qemux86-64.rootfs-20260702083151.ext4`
- Stable filename (symlink to latest artifact), for example:
  - `core-image-minimal-qemux86-64.rootfs.ext4`

Use stable symlink names in scripts when you always want the latest build.
Use timestamped names for archival, release capture, or exact reproducibility.

## File Types And Purpose

### Kernel Image (`bzImage*.bin`)

Examples:

- `bzImage--<kernel-id>-qemux86-64-<timestamp>.bin`
- `bzImage`
- `bzImage-qemux86-64.bin`

What it is:

- Linux kernel binary used for booting QEMU or target hardware.

When to use:

- Boot tests, runqemu workflows, and kernel-level validation.

### Root Filesystem Disk Image (`*.rootfs*.ext4`)

Examples:

- `core-image-minimal-qemux86-64.rootfs-<timestamp>.ext4`
- `core-image-minimal-qemux86-64.rootfs.ext4`

What it is:

- Bootable ext4 root filesystem image.

When to use:

- QEMU boots, flashing workflows that accept raw/ext4 images, and mount-based
  inspection.

### Root Filesystem Archive (`*.rootfs*.tar.bz2`)

Examples:

- `core-image-minimal-qemux86-64.rootfs-<timestamp>.tar.bz2`
- `core-image-minimal-qemux86-64.rootfs.tar.bz2`

What it is:

- Compressed tar archive of the root filesystem tree.

When to use:

- Fast file-level inspection, post-processing, and artifact transfer.

Note:

- This is not a bootable disk image by itself.

### Installed Package Manifest (`*.rootfs*.manifest`)

Examples:

- `core-image-minimal-qemux86-64.rootfs-<timestamp>.manifest`
- `core-image-minimal-qemux86-64.rootfs.manifest`

What it is:

- Text list of packages included in the generated image.

When to use:

- Verifying whether a package is present in the image.
- Comparing package contents across builds.

### QEMU Boot Config (`*.rootfs*.qemuboot.conf`)

Examples:

- `core-image-minimal-qemux86-64.rootfs-<timestamp>.qemuboot.conf`
- `core-image-minimal-qemux86-64.rootfs.qemuboot.conf`

What it is:

- Metadata file used by runqemu (kernel/rootfs/machine parameters).

When to use:

- Reproducing QEMU boots with the exact build artifacts.

### SPDX SBOM Bundle (`*.rootfs*.spdx.tar.zst`)

Examples:

- `core-image-minimal-qemux86-64.rootfs-<timestamp>.spdx.tar.zst`
- `core-image-minimal-qemux86-64.rootfs.spdx.tar.zst`

What it is:

- Software Bill of Materials (SBOM) in SPDX format, compressed as tar+zstd.

When to use:

- License/compliance review.
- Supply-chain and security analysis.

### Runtime Test Metadata (`*.rootfs*.testdata.json`)

Examples:

- `core-image-minimal-qemux86-64.rootfs-<timestamp>.testdata.json`
- `core-image-minimal-qemux86-64.rootfs.testdata.json`

What it is:

- JSON metadata consumed by Yocto runtime test tooling.

When to use:

- Automated test pipelines and artifact-aware test execution.

### Kernel Modules Archive (`modules*.tgz`)

Examples:

- `modules--<kernel-id>-qemux86-64-<timestamp>.tgz`
- `modules-qemux86-64.tgz`

What it is:

- Tarball containing kernel modules for the built kernel version.

When to use:

- Module distribution, offline module packaging, and kernel/module pairing
  checks.

## Quick "Which One For What" Cheat Sheet

- Boot in QEMU quickly:
  - `bzImage` + `core-image-minimal-qemux86-64.rootfs.ext4`
- Check if a package is in the image:
  - `core-image-minimal-qemux86-64.rootfs.manifest`
- Inspect filesystem contents without mounting ext4:
  - `core-image-minimal-qemux86-64.rootfs.tar.bz2`
- Compliance/security inventory:
  - `core-image-minimal-qemux86-64.rootfs.spdx.tar.zst`
- Run test tooling against image metadata:
  - `core-image-minimal-qemux86-64.rootfs.testdata.json`
- Validate kernel modules matching build:
  - `modules-qemux86-64.tgz`

## Repository-Specific Note

This repository stages deploy outputs into `out/images/` via the build wrapper.
The underlying Yocto deploy source remains `build/tmp/deploy/images/<machine>/`.
