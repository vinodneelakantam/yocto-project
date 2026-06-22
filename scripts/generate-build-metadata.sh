#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/out}"
IMAGE_TARGET="${2:-${IMAGE_TARGET:-core-image-minimal}}"
MACHINE_NAME="${3:-${MACHINE:-unknown}}"
METADATA_DIR="$OUT_DIR/metadata"
METADATA_FILE="$METADATA_DIR/build-metadata.json"

mkdir -p "$METADATA_DIR"

HEAD_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")"
HEAD_SHORT="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
SUBMODULE_FILE="$METADATA_DIR/submodules.txt"
git -C "$ROOT_DIR" submodule status --recursive >"$SUBMODULE_FILE" 2>/dev/null || true

IMAGE_DIGEST_FILE="$METADATA_DIR/image-sha256.txt"
if find "$OUT_DIR/images" -type f \( -name "*.wic" -o -name "*.wic.bz2" -o -name "*.tar.bz2" -o -name "*.ext4" -o -name "*.rootfs.*" \) | head -n1 >/dev/null 2>&1; then
  find "$OUT_DIR/images" -type f \( -name "*.wic" -o -name "*.wic.bz2" -o -name "*.tar.bz2" -o -name "*.ext4" -o -name "*.rootfs.*" \) \
    -exec sha256sum {} + \
    | sort >"$IMAGE_DIGEST_FILE"
else
  : >"$IMAGE_DIGEST_FILE"
fi

cat >"$METADATA_FILE" <<EOF
{
  "timestamp_utc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "image_target": "$IMAGE_TARGET",
  "machine": "$MACHINE_NAME",
  "git_revision": "$HEAD_SHA",
  "git_revision_short": "$HEAD_SHORT",
  "submodules_file": "metadata/submodules.txt",
  "image_digest_file": "metadata/image-sha256.txt"
}
EOF

echo "[metadata] Wrote $METADATA_FILE"
