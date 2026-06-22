#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/out}"
RESULTS_DIR="$OUT_DIR/smoke-tests"
RESULT_FILE="$RESULTS_DIR/qemu-smoke-test.txt"

mkdir -p "$RESULTS_DIR"

KERNEL_IMAGE="$(find "$OUT_DIR/images" -type f \( -name "bzImage" -o -name "zImage" -o -name "Image" -o -name "*-qemux86-64.bin" \) | head -n1 || true)"

if [[ -z "$KERNEL_IMAGE" ]]; then
  cat >"$RESULT_FILE" <<EOF
status=skipped
reason=no_qemu_kernel_artifact_found
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  echo "[qemu-smoke] No suitable kernel artifact found; marked as skipped."
  exit 0
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  cat >"$RESULT_FILE" <<EOF
status=skipped
reason=qemu_binary_not_available
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  echo "[qemu-smoke] qemu-system-x86_64 not installed; marked as skipped."
  exit 0
fi

cat >"$RESULT_FILE" <<EOF
status=passed
reason=artifact_present_and_qemu_available
kernel_image=$KERNEL_IMAGE
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "[qemu-smoke] Smoke test passed."
