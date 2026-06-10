#!/usr/bin/env bash
set -euo pipefail

IMAGE_TARGET="${1:-core-image-minimal}"
CLEAN_BUILD="${2:-false}"
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$BUILD_ROOT/out"
YOCTO_BUILD_DIR="$BUILD_ROOT/build"

mkdir -p "$OUT_DIR"

if [[ ! -f "$BUILD_ROOT/oe-init-build-env" ]]; then
  echo "Missing oe-init-build-env in $BUILD_ROOT"
  echo "Clone or mount your Yocto tree so oe-init-build-env is available."
  exit 1
fi

# shellcheck disable=SC1091
source "$BUILD_ROOT/oe-init-build-env" "$YOCTO_BUILD_DIR" >/dev/null

if [[ "$CLEAN_BUILD" == "true" ]]; then
  bitbake -c cleansstate "$IMAGE_TARGET"
fi

bitbake "$IMAGE_TARGET"

# Collect common deploy outputs as CI artifacts.
DEPLOY_DIR="$YOCTO_BUILD_DIR/tmp/deploy/images"
if [[ -d "$DEPLOY_DIR" ]]; then
  cp -a "$DEPLOY_DIR" "$OUT_DIR/images"
fi

cat > "$OUT_DIR/build-summary.txt" <<EOF
Build completed successfully.
Image target: $IMAGE_TARGET
Build dir: $YOCTO_BUILD_DIR
Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "Artifacts staged at $OUT_DIR"
