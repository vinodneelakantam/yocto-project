#!/usr/bin/env bash
set -euo pipefail

# Required: GH_REPO (owner/repo), VPS_HOST, VPS_USER, VPS_SSH_KEY
# Optional: VPS_PORT, VPS_BUILD_ROOT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib-gh.sh"

required=(GH_REPO VPS_HOST VPS_USER VPS_SSH_KEY)
for key in "${required[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required environment variable: $key"
    exit 1
  fi
done

GH_BIN="$(require_gh_cli)" || exit 1
require_gh_auth "$GH_BIN" || exit 1

printf '%s' "$VPS_HOST" | "$GH_BIN" secret set VPS_HOST --repo "$GH_REPO" --body -
printf '%s' "$VPS_USER" | "$GH_BIN" secret set VPS_USER --repo "$GH_REPO" --body -
printf '%s' "$VPS_SSH_KEY" | "$GH_BIN" secret set VPS_SSH_KEY --repo "$GH_REPO" --body -

if [[ -n "${VPS_PORT:-}" ]]; then
  printf '%s' "$VPS_PORT" | "$GH_BIN" secret set VPS_PORT --repo "$GH_REPO" --body -
fi

if [[ -n "${VPS_BUILD_ROOT:-}" ]]; then
  printf '%s' "$VPS_BUILD_ROOT" | "$GH_BIN" secret set VPS_BUILD_ROOT --repo "$GH_REPO" --body -
fi

echo "Secrets configured for $GH_REPO"
