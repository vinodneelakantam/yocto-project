#!/usr/bin/env bash
set -euo pipefail

# Required: GH_REPO (owner/repo)
# Optional: IMAGE_TARGET (default core-image-minimal), CLEAN_BUILD (default false)

: "${GH_REPO:?Missing GH_REPO (owner/repo)}"
IMAGE_TARGET="${IMAGE_TARGET:-core-image-minimal}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"

if ! command -v gh >/dev/null 2>&1; then
  if [[ -x "./.local/bin/gh" ]]; then
    GH_BIN="./.local/bin/gh"
  elif [[ -x "./scripts/github/install-gh-from-github.sh" ]]; then
    GH_BIN="$(./scripts/github/install-gh-from-github.sh)"
  else
    echo "GitHub CLI (gh) is required but not found."
    exit 1
  fi
else
  GH_BIN="$(command -v gh)"
fi

"$GH_BIN" auth status >/dev/null 2>&1 || {
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
}

"$GH_BIN" workflow run remote-yocto-build.yml --repo "$GH_REPO" -f image="$IMAGE_TARGET" -f clean="$CLEAN_BUILD"

echo "Workflow dispatched. Watching latest run..."
"$GH_BIN" run watch --repo "$GH_REPO" --exit-status

echo "Latest runs:"
"$GH_BIN" run list --repo "$GH_REPO" --workflow remote-yocto-build.yml --limit 3
