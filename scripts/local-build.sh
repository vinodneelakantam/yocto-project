#!/usr/bin/env bash
set -euo pipefail

IMAGE_TARGET="${1:-core-image-minimal}"
CLEAN_BUILD="${2:-true}"
BOOTSTRAP_PACKAGES="${BOOTSTRAP_PACKAGES:-true}"
BOOTSTRAP_RAN="false"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[local-build] Root directory: $ROOT_DIR"
echo "[local-build] Image target: $IMAGE_TARGET"
echo "[local-build] Clean build: $CLEAN_BUILD"
echo "[local-build] Build variant: ${BUILD_VARIANT:-<none, uses local.conf DISTRO>}"
echo "[local-build] Bootstrap packages: $BOOTSTRAP_PACKAGES"

echo "[local-build] Initializing submodules..."
git submodule update --init --recursive

if [[ "$BOOTSTRAP_PACKAGES" == "true" ]]; then
  if [[ -x scripts/bootstrap-worker-packages.sh ]]; then
    echo "[local-build] Installing build dependencies..."
    ./scripts/bootstrap-worker-packages.sh
    BOOTSTRAP_RAN="true"
  else
    echo "[local-build] bootstrap-worker-packages.sh not found or not executable; skipping package bootstrap."
  fi
else
  echo "[local-build] Package bootstrap disabled by BOOTSTRAP_PACKAGES=false"
fi

echo "[local-build] Running host-tools sanity check..."
if [[ "$BOOTSTRAP_RAN" == "true" ]]; then
  echo "[local-build] Host-tools sanity check already executed by bootstrap script; skipping duplicate check."
elif [[ -x scripts/devcontainer-sanity-check.sh ]]; then
  if ! ./scripts/devcontainer-sanity-check.sh; then
    echo "[local-build] ERROR: Host-tools sanity check failed."
    echo "[local-build] Fix by enabling bootstrap (BOOTSTRAP_PACKAGES=true) or installing missing packages manually."
    exit 1
  fi
else
  echo "[local-build] WARNING: scripts/devcontainer-sanity-check.sh not found or not executable; skipping sanity check."
fi

echo "[local-build] Starting Yocto build..."
BOOTSTRAP_PACKAGES=false ./scripts/remote-build.sh "$IMAGE_TARGET" "$CLEAN_BUILD"

echo "[local-build] Build finished."

VISUALIZE_BUILD_LOGS="${VISUALIZE_BUILD_LOGS:-true}"
if [[ "$VISUALIZE_BUILD_LOGS" == "true" ]]; then
  if [[ -x scripts/generate-bitbake-artifacts.sh ]]; then
    echo "[local-build] Generating BitBake artifact bundle (taskexp graphs + log visualization)..."
    if _ARTIFACT_OUTPUT="$(./scripts/generate-bitbake-artifacts.sh "$IMAGE_TARGET" 2>&1)"; then
      echo "$_ARTIFACT_OUTPUT" | tail -n 1
    else
      echo "[local-build] WARNING: BitBake artifact bundle generation failed (continuing)."
    fi
  else
    echo "[local-build] SKIP artifact bundle: scripts/generate-bitbake-artifacts.sh not executable."
  fi
else
  echo "[local-build] BitBake artifact bundle skipped (VISUALIZE_BUILD_LOGS=false)."
fi

# ── GitHub Actions cache seed ─────────────────────────────────────────────
# After a successful local build, trigger the seed-cache-from-codespace
# workflow on the self-hosted Codespace runner so the resulting sstate-cache
# and downloads are available to GitHub-hosted CI runners.
#
# Prerequisites:
#   • gh CLI installed and authenticated  (gh auth status)
#   • A self-hosted runner is active in the Codespace (label: codespace-yocto)
#
# Opt out by setting SEED_GH_CACHE=false before running this script.
SEED_GH_CACHE="${SEED_GH_CACHE:-true}"
if [[ "$SEED_GH_CACHE" == "true" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "[local-build] SKIP cache seed: gh CLI not found."
  elif ! gh auth status >/dev/null 2>&1; then
    echo "[local-build] SKIP cache seed: gh CLI not authenticated (run 'gh auth login')."
  else
    _CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
    echo "[local-build] Triggering GitHub Actions cache seed workflow on branch '$_CURRENT_BRANCH'..."

    if ! gh workflow run seed-cache-from-codespace.yml \
        --ref "$_CURRENT_BRANCH" \
        -f image="$IMAGE_TARGET" \
        -f direction="push" 2>&1; then
      echo "[local-build] WARNING: Failed to trigger cache seed workflow (runner may be offline or gh permissions insufficient)."
    else
      # Wait for the newly queued run to appear in the API (usually < 5 s).
      echo "[local-build] Waiting for run to register..."
      _SEED_RUN_ID=""
      for _i in 1 2 3 4 5 6 7 8 9 10; do
        sleep 3
        _SEED_RUN_ID="$(gh run list \
          --workflow=seed-cache-from-codespace.yml \
          --branch "$_CURRENT_BRANCH" \
          --limit 1 \
          --json databaseId \
          --jq '.[0].databaseId' 2>/dev/null || true)"
        [[ -n "$_SEED_RUN_ID" ]] && break
      done

      if [[ -z "$_SEED_RUN_ID" ]]; then
        echo "[local-build] WARNING: Could not find cache seed run ID — cache may not have been uploaded."
      else
        # Block until the workflow job completes.  Because the self-hosted
        # runner is local to this Codespace, the wait is typically < 2 min.
        # This prevents the Codespace from going idle and killing the runner
        # before the cache upload finishes.
        echo "[local-build] Waiting for cache seed run #${_SEED_RUN_ID} to complete (this keeps the Codespace alive)..."
        if gh run watch "$_SEED_RUN_ID" --exit-status; then
          echo "[local-build] Cache seeded to GitHub Actions cache successfully."
        else
          echo "[local-build] WARNING: Cache seed workflow run failed — check Actions tab for details."
        fi
      fi
    fi
  fi
else
  echo "[local-build] Cache seed skipped (SEED_GH_CACHE=false)."
fi
# ─────────────────────────────────────────────────────────────────────────
echo "[local-build] Outputs:"
echo "  - $ROOT_DIR/out"
echo "  - $ROOT_DIR/out/build-summary.txt"
