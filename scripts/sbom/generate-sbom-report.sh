#!/usr/bin/env bash
set -euo pipefail

# Produces a CycloneDX SBOM and a CVE triage report from a completed Yocto
# build's staged output (out/images/<machine>/). See
# docs/sbom-and-cve-workflow.md for the full pipeline description.

IMAGE_TARGET="${1:-core-image-minimal}"
MACHINE="${2:-qemux86-64}"
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-$BUILD_ROOT/out}"
IMAGES_DIR="$OUT_DIR/images/$MACHINE"
SBOM_DIR="$OUT_DIR/sbom"
SEVERITY_THRESHOLD="${CVE_SEVERITY_THRESHOLD:-7.0}"

mkdir -p "$SBOM_DIR"

IMAGE_LINK_NAME="${IMAGE_TARGET}-${MACHINE}.rootfs"
SPDX_BUNDLE="$IMAGES_DIR/${IMAGE_LINK_NAME}.spdx.tar.zst"
CVE_MANIFEST="$IMAGES_DIR/${IMAGE_LINK_NAME}.json"

if [[ ! -f "$SPDX_BUNDLE" ]]; then
  echo "ERROR: SPDX bundle not found: $SPDX_BUNDLE" >&2
  echo "Hint: create-spdx is enabled by default (poky.conf); confirm the build completed and staged out/images/." >&2
  exit 1
fi

if ! command -v zstd >/dev/null 2>&1; then
  echo "ERROR: 'zstd' is required to read the SPDX bundle but was not found on PATH." >&2
  exit 1
fi

python3 "$BUILD_ROOT/scripts/sbom/spdx-to-cyclonedx.py" \
  "$SPDX_BUNDLE" \
  --image-name "$IMAGE_TARGET" \
  --output "$SBOM_DIR/${IMAGE_LINK_NAME}.cdx.json"

if [[ ! -f "$CVE_MANIFEST" ]]; then
  echo "WARNING: CVE manifest not found: $CVE_MANIFEST"
  echo "Hint: set ENABLE_CVE_CHECK=true when running the build to produce it."
  exit 0
fi

python3 "$BUILD_ROOT/scripts/sbom/triage-cves.py" \
  "$CVE_MANIFEST" \
  --waivers "$BUILD_ROOT/scripts/sbom/cve-waivers.json" \
  --threshold "$SEVERITY_THRESHOLD" \
  --report "$SBOM_DIR/cve-triage-summary.md"
