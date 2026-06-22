#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <run-id> <artifact-name> <target-environment>"
  exit 1
fi

RUN_ID="$1"
ARTIFACT_NAME="$2"
TARGET_ENV="$3"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/out/promotion"
ARCHIVE_DIR="$OUT_DIR/input-artifact"
PROMOTION_METADATA="$OUT_DIR/promotion-metadata.json"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "GITHUB_TOKEN is required."
  exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "GITHUB_REPOSITORY is required."
  exit 1
fi

mkdir -p "$ARCHIVE_DIR"

API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${RUN_ID}/artifacts"
ARTIFACT_ID="$(curl -fsSL \
  -u "x-access-token:${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "$API_URL" \
  | python -c 'import json,sys; d=json.load(sys.stdin); n=sys.argv[1]; print(next((str(a["id"]) for a in d.get("artifacts",[]) if a.get("name")==n), ""))' "$ARTIFACT_NAME")"

if [[ -z "$ARTIFACT_ID" ]]; then
  echo "Artifact '$ARTIFACT_NAME' was not found in run '$RUN_ID'."
  exit 1
fi

ZIP_PATH="$OUT_DIR/${ARTIFACT_NAME}.zip"
curl -fsSL \
  -u "x-access-token:${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/artifacts/${ARTIFACT_ID}/zip" \
  -o "$ZIP_PATH"

unzip -o -q "$ZIP_PATH" -d "$ARCHIVE_DIR"
sha256sum "$ZIP_PATH" >"$OUT_DIR/${ARTIFACT_NAME}.zip.sha256"

cat >"$PROMOTION_METADATA" <<EOF
{
  "source_run_id": "$RUN_ID",
  "source_artifact_name": "$ARTIFACT_NAME",
  "target_environment": "$TARGET_ENV",
  "promoted_at_utc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "zip_sha256_file": "${ARTIFACT_NAME}.zip.sha256"
}
EOF

echo "[promotion] Prepared promoted artifact at $OUT_DIR"
