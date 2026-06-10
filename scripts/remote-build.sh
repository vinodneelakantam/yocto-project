#!/usr/bin/env bash
set -euo pipefail

IMAGE_TARGET="${1:-core-image-minimal}"
CLEAN_BUILD="${2:-false}"
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$BUILD_ROOT/out"
YOCTO_BUILD_DIR="$BUILD_ROOT/build"
POKY_INIT_SCRIPT="$BUILD_ROOT/sources/poky/oe-init-build-env"

mkdir -p "$OUT_DIR"

if [[ ! -f "$POKY_INIT_SCRIPT" ]]; then
  echo "Missing poky init script: $POKY_INIT_SCRIPT"
  echo "Initialize source submodules before building:"
  echo "  git submodule update --init --recursive"
  exit 1
fi

# shellcheck disable=SC1091
source "$POKY_INIT_SCRIPT" "$YOCTO_BUILD_DIR" >/dev/null

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
