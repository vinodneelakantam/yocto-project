#!/usr/bin/env bash
set -euo pipefail

# Required: GH_REPO (owner/repo)
# Optional: IMAGE_TARGET (default core-image-minimal), CLEAN_BUILD (default false)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib-gh.sh"

: "${GH_REPO:?Missing GH_REPO (owner/repo)}"
IMAGE_TARGET="${IMAGE_TARGET:-core-image-minimal}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"

GH_BIN="$(require_gh_cli)" || exit 1
require_gh_auth "$GH_BIN" || exit 1

"$GH_BIN" workflow run remote-yocto-build.yml --repo "$GH_REPO" -f image="$IMAGE_TARGET" -f clean="$CLEAN_BUILD"

echo "Workflow dispatched. Watching latest run..."
"$GH_BIN" run watch --repo "$GH_REPO" --exit-status

echo "Latest runs:"
"$GH_BIN" run list --repo "$GH_REPO" --workflow remote-yocto-build.yml --limit 3
