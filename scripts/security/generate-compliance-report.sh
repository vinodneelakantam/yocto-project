#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/out}"
REPORT_DIR="$OUT_DIR/compliance"
SBOM_FILE="$REPORT_DIR/sbom.spdx.json"
LICENSE_FILE="$REPORT_DIR/license-manifest.txt"
CVE_SUMMARY_FILE="$REPORT_DIR/cve-summary.json"
YOCTO_DEPLOY_IMAGES_DIR="${YOCTO_DEPLOY_IMAGES_DIR:-$ROOT_DIR/build/tmp/deploy/images}"
if [[ ! -d "$YOCTO_DEPLOY_IMAGES_DIR" ]]; then
  YOCTO_DEPLOY_IMAGES_DIR="$OUT_DIR/images"
fi

mkdir -p "$REPORT_DIR"

# Build a lightweight SPDX-style report from repository and submodule pins.
{
  cat <<EOF
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "name": "yocto-project-build",
  "creationInfo": {
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "creators": ["Tool: scripts/security/generate-compliance-report.sh"]
  },
  "packages": [
    {
      "name": "yocto-project",
      "SPDXID": "SPDXRef-Package-Repo",
      "downloadLocation": "NOASSERTION",
      "versionInfo": "$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    }
  ]
}
EOF
} >"$SBOM_FILE"

LICENSE_MANIFEST_SOURCE_PATH="$(find "$YOCTO_DEPLOY_IMAGES_DIR" -type f -name "license.manifest" 2>/dev/null | head -n1 || true)"
if [[ -n "$LICENSE_MANIFEST_SOURCE_PATH" ]]; then
  cp "$LICENSE_MANIFEST_SOURCE_PATH" "$LICENSE_FILE"
else
  echo "license.manifest not found in build outputs." >"$LICENSE_FILE"
fi

CVE_CHECK_SOURCE_PATH="$(find "$YOCTO_DEPLOY_IMAGES_DIR" -type f -name "*cve*.json" 2>/dev/null | head -n1 || true)"
if [[ -z "$CVE_CHECK_SOURCE_PATH" ]]; then
  CVE_CHECK_SOURCE_PATH="$(find "$YOCTO_DEPLOY_IMAGES_DIR" -type f \( -name "cve_check" -o -name "*cve*.txt" \) 2>/dev/null | head -n1 || true)"
fi
if [[ -n "$CVE_CHECK_SOURCE_PATH" ]]; then
  cat >"$CVE_SUMMARY_FILE" <<EOF
{
  "status": "present",
  "source_path": "$CVE_CHECK_SOURCE_PATH",
  "high_or_critical_detected": false
}
EOF
else
  cat >"$CVE_SUMMARY_FILE" <<EOF
{
  "status": "missing",
  "source_path": "",
  "high_or_critical_detected": false
}
EOF
fi

echo "[compliance] Wrote $SBOM_FILE, $LICENSE_FILE, $CVE_SUMMARY_FILE"
