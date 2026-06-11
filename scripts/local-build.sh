#!/usr/bin/env bash
set -euo pipefail

IMAGE_TARGET="${1:-core-image-minimal}"
CLEAN_BUILD="${2:-false}"
BOOTSTRAP_PACKAGES="${BOOTSTRAP_PACKAGES:-true}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[local-build] Root directory: $ROOT_DIR"
echo "[local-build] Image target: $IMAGE_TARGET"
echo "[local-build] Clean build: $CLEAN_BUILD"
echo "[local-build] Bootstrap packages: $BOOTSTRAP_PACKAGES"

echo "[local-build] Initializing submodules..."
git submodule update --init --recursive

if [[ "$BOOTSTRAP_PACKAGES" == "true" ]]; then
  if [[ -x scripts/bootstrap-worker-packages.sh ]]; then
    echo "[local-build] Installing build dependencies..."
    ./scripts/bootstrap-worker-packages.sh
  else
    echo "[local-build] bootstrap-worker-packages.sh not found or not executable; skipping package bootstrap."
  fi
else
  echo "[local-build] Package bootstrap disabled by BOOTSTRAP_PACKAGES=false"
fi

echo "[local-build] Starting Yocto build..."
./scripts/remote-build.sh "$IMAGE_TARGET" "$CLEAN_BUILD"

echo "[local-build] Build finished."
echo "[local-build] Outputs:"
echo "  - $ROOT_DIR/out"
echo "  - $ROOT_DIR/out/build-summary.txt"
