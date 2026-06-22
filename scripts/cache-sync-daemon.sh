#!/usr/bin/env bash
# cache-sync-daemon.sh — Periodic Yocto cache sync between Codespace and
# GitHub Actions cache.
#
# Runs as a background process inside the Codespace.  Every SYNC_INTERVAL
# seconds it triggers the sync-yocto-cache workflow on the self-hosted
# Codespace runner, which:
#   push  — hard-links new sstate/download files from this Codespace into
#            the runner workspace and saves them to GitHub Actions cache
#            (available to GitHub-hosted CI runners on the next build).
#   pull  — restores the latest GitHub Actions cache into the runner
#            workspace and merges any new files into this Codespace
#            (picks up packages built by CI that you haven't built locally).
#
# Usage:
#   # Start in background (called automatically by devcontainer postStartCommand)
#   ./scripts/cache-sync-daemon.sh &
#   echo $! > /tmp/cache-sync-daemon.pid
#
#   # Stop
#   kill "$(cat /tmp/cache-sync-daemon.pid)"
#
# Environment variables:
#   SYNC_INTERVAL   Seconds between sync cycles.  Default: 1800 (30 min).
#   SYNC_DIRECTION  both | push | pull.  Default: both.
#   SYNC_IMAGE      BitBake image target for the sstate cache key.
#                   Default: core-image-minimal.
#   SYNC_LOG        Path to write log output.  Default: /tmp/cache-sync-daemon.log.

set -euo pipefail

SYNC_INTERVAL="${SYNC_INTERVAL:-1800}"
SYNC_DIRECTION="${SYNC_DIRECTION:-both}"
SYNC_IMAGE="${SYNC_IMAGE:-core-image-minimal}"
SYNC_LOG="${SYNC_LOG:-/tmp/cache-sync-daemon.log}"
PID_FILE="/tmp/cache-sync-daemon.pid"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
  echo "[cache-sync $(date -u '+%H:%M:%S')] $*" | tee -a "$SYNC_LOG"
}

# ── Preflight checks ────────────────────────────────────────────────────────

if ! command -v gh >/dev/null 2>&1; then
  log "ERROR: gh CLI not found.  Install it or skip daemon startup."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  log "ERROR: gh CLI not authenticated.  Run 'gh auth login' then restart the daemon."
  exit 1
fi

# Write PID so the daemon can be stopped easily.
echo "$$" > "$PID_FILE"
log "Daemon started (PID $$).  Interval: ${SYNC_INTERVAL}s  Direction: $SYNC_DIRECTION"
log "Log file: $SYNC_LOG   PID file: $PID_FILE"

# ── Sync function ────────────────────────────────────────────────────────────

do_sync() {
  local branch
  branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"

  log "Triggering cache sync (direction=$SYNC_DIRECTION, branch=$branch)..."

  if ! gh workflow run seed-cache-from-codespace.yml \
      --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '')" \
      --ref "$branch" \
      -f image="$SYNC_IMAGE" \
      -f direction="$SYNC_DIRECTION" 2>&1 | tee -a "$SYNC_LOG"; then
    log "WARNING: Failed to trigger workflow (runner offline or gh permissions insufficient)."
    return 0
  fi

  # Wait a few seconds for the run to register in the API.
  sleep 5
  local run_id
  run_id="$(gh run list \
    --workflow=seed-cache-from-codespace.yml \
    --branch "$branch" \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId' 2>/dev/null || echo '')"

  if [[ -z "$run_id" ]]; then
    log "WARNING: Could not resolve run ID — skipping wait."
    return 0
  fi

  log "Waiting for run #${run_id} to complete..."
  if gh run watch "$run_id" --exit-status 2>&1 | tee -a "$SYNC_LOG"; then
    log "Sync run #${run_id} completed successfully."
  else
    log "WARNING: Sync run #${run_id} failed — check the Actions tab for details."
  fi
}

# ── Main loop ────────────────────────────────────────────────────────────────

# Run immediately on startup so a freshly started Codespace gets CI cache
# right away (pull direction).
if [[ "$SYNC_DIRECTION" == "both" || "$SYNC_DIRECTION" == "pull" ]]; then
  log "Running initial pull on startup..."
  SYNC_DIRECTION_ORIG="$SYNC_DIRECTION"
  SYNC_DIRECTION="pull" do_sync || true
  SYNC_DIRECTION="$SYNC_DIRECTION_ORIG"
fi

while true; do
  log "Next sync in ${SYNC_INTERVAL}s..."
  sleep "$SYNC_INTERVAL"
  do_sync || true
done
