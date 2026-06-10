#!/usr/bin/env bash
set -euo pipefail

# Required: GH_REPO_NAME
# Optional: GH_OWNER, GH_VISIBILITY (public|private, default public)

: "${GH_REPO_NAME:?Missing GH_REPO_NAME}"
GH_OWNER="${GH_OWNER:-}"
GH_VISIBILITY="${GH_VISIBILITY:-public}"

if command -v gh >/dev/null 2>&1; then
  GH_BIN="$(command -v gh)"
elif [[ -x "./.local/bin/gh" ]]; then
  GH_BIN="./.local/bin/gh"
elif [[ -x "./scripts/github/install-gh-from-github.sh" ]]; then
  GH_BIN="$(./scripts/github/install-gh-from-github.sh)"
else
  echo "GitHub CLI is required but not found."
  exit 1
fi

"$GH_BIN" auth status >/dev/null 2>&1 || {
  echo "GitHub CLI is not authenticated. Run: ./.local/bin/gh auth login --web"
  exit 1
}

if [[ -n "$GH_OWNER" ]]; then
  FULL_REPO="$GH_OWNER/$GH_REPO_NAME"
else
  login="$($GH_BIN api user -q .login)"
  FULL_REPO="$login/$GH_REPO_NAME"
fi

"$GH_BIN" repo create "$FULL_REPO" --"$GH_VISIBILITY" --source . --remote origin --push

echo "Created and pushed: $FULL_REPO"
