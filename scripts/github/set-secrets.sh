#!/usr/bin/env bash
set -euo pipefail

# Required: GH_REPO (owner/repo), VPS_HOST, VPS_USER, VPS_SSH_KEY
# Optional: VPS_PORT, VPS_BUILD_ROOT

required=(GH_REPO VPS_HOST VPS_USER VPS_SSH_KEY)
for key in "${required[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required environment variable: $key"
    exit 1
  fi
done

GH_BIN="${GH_BIN:-}"
if [[ -z "$GH_BIN" ]]; then
  if command -v gh >/dev/null 2>&1; then
    GH_BIN="$(command -v gh)"
  elif [[ -x "./.local/bin/gh" ]]; then
    GH_BIN="./.local/bin/gh"
  else
    echo "GitHub CLI (gh) is required but not found."
    exit 1
  fi
fi

"$GH_BIN" auth status >/dev/null 2>&1 || {
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
}

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
