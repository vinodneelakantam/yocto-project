#!/usr/bin/env bash
set -euo pipefail

# Required: GH_REPO_NAME
# Optional: GH_OWNER, GH_VISIBILITY (public|private, default public)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib-gh.sh"

: "${GH_REPO_NAME:?Missing GH_REPO_NAME}"
GH_OWNER="${GH_OWNER:-}"
GH_VISIBILITY="${GH_VISIBILITY:-public}"

GH_BIN="$(require_gh_cli)" || exit 1
require_gh_auth "$GH_BIN" || exit 1

if [[ -n "$GH_OWNER" ]]; then
  FULL_REPO="$GH_OWNER/$GH_REPO_NAME"
else
  login="$($GH_BIN api user -q .login)"
  FULL_REPO="$login/$GH_REPO_NAME"
fi

"$GH_BIN" repo create "$FULL_REPO" --"$GH_VISIBILITY" --source . --remote origin --push

echo "Created and pushed: $FULL_REPO"
