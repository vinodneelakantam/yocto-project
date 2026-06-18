#!/usr/bin/env bash
set -euo pipefail

IMAGE_TARGET="${1:-core-image-minimal}"
CLEAN_BUILD="${2:-false}"
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$BUILD_ROOT/out"
YOCTO_BUILD_DIR="$BUILD_ROOT/build"
POKY_INIT_SCRIPT="$BUILD_ROOT/sources/poky/oe-init-build-env"
WORKER_BOOTSTRAP_SCRIPT="$BUILD_ROOT/scripts/bootstrap-worker-packages.sh"
CACHE_ROOT="$BUILD_ROOT/.cache/yocto"
DL_DIR="$CACHE_ROOT/downloads"
SSTATE_DIR="$CACHE_ROOT/sstate-cache"
CENTRAL_CACHE_URI="${YOCTO_CENTRAL_CACHE_RSYNC:-}"

sync_cache_dir() {
  local direction="$1"
  local remote_subdir="$2"
  local local_dir="$3"

  if [[ -z "$CENTRAL_CACHE_URI" ]]; then
    return 0
  fi

  if ! command -v rsync >/dev/null 2>&1; then
    echo "WARNING: rsync not found; skipping central cache sync."
    return 0
  fi

  mkdir -p "$local_dir"

  if [[ "$direction" == "pull" ]]; then
    rsync -az "${CENTRAL_CACHE_URI%/}/$remote_subdir/" "$local_dir/" \
      || echo "WARNING: Failed to pull central cache subdir '$remote_subdir'."
    return 0
  fi

  rsync -az "$local_dir/" "${CENTRAL_CACHE_URI%/}/$remote_subdir/" \
    || echo "WARNING: Failed to push central cache subdir '$remote_subdir'."
}

sync_central_cache_pull() {
  if [[ -n "$CENTRAL_CACHE_URI" ]]; then
    echo "Syncing Yocto cache from central endpoint: $CENTRAL_CACHE_URI"
  fi
  sync_cache_dir pull downloads "$DL_DIR"
  sync_cache_dir pull sstate-cache "$SSTATE_DIR"
}

sync_central_cache_push() {
  if [[ -n "$CENTRAL_CACHE_URI" ]]; then
    echo "Syncing Yocto cache to central endpoint: $CENTRAL_CACHE_URI"
  fi
  sync_cache_dir push downloads "$DL_DIR"
  sync_cache_dir push sstate-cache "$SSTATE_DIR"
}

mkdir -p "$OUT_DIR"
mkdir -p "$DL_DIR" "$SSTATE_DIR"

sync_central_cache_pull

if [[ -x "$WORKER_BOOTSTRAP_SCRIPT" ]]; then
  "$WORKER_BOOTSTRAP_SCRIPT"
fi

if [[ ! -f "$POKY_INIT_SCRIPT" ]]; then
  echo "Missing poky init script: $POKY_INIT_SCRIPT"
  echo "Initialize source submodules before building:"
  echo "  git submodule update --init --recursive"
  exit 1
fi

# `oe-init-build-env` references optional env vars that may be unset.
# Temporarily disable nounset so strict mode in this wrapper does not break it.
nounset_was_set=0
if [[ -o nounset ]]; then
  nounset_was_set=1
  set +u
fi

# shellcheck disable=SC1091
source "$POKY_INIT_SCRIPT" "$YOCTO_BUILD_DIR" >/dev/null

if [[ "$nounset_was_set" -eq 1 ]]; then
  set -u
fi

LOCAL_CONF="$YOCTO_BUILD_DIR/conf/local.conf"
if [[ -f "$LOCAL_CONF" ]]; then
  if ! grep -q '^DL_DIR\s*=' "$LOCAL_CONF"; then
    printf 'DL_DIR = "%s"\n' "$DL_DIR" >> "$LOCAL_CONF"
  fi
  if ! grep -q '^SSTATE_DIR\s*=' "$LOCAL_CONF"; then
    printf 'SSTATE_DIR = "%s"\n' "$SSTATE_DIR" >> "$LOCAL_CONF"
  fi
fi

if [[ "$CLEAN_BUILD" == "true" ]]; then
  bitbake -c cleansstate "$IMAGE_TARGET"
fi

bitbake "$IMAGE_TARGET"

sync_central_cache_push

# Collect common deploy outputs as CI artifacts.
DEPLOY_DIR="$YOCTO_BUILD_DIR/tmp/deploy/images"
if [[ -d "$DEPLOY_DIR" ]]; then
  cp -a "$DEPLOY_DIR" "$OUT_DIR/images"
fi

cat > "$OUT_DIR/build-summary.txt" <<EOF
Build completed successfully.
Image target: $IMAGE_TARGET
Build dir: $YOCTO_BUILD_DIR
DL_DIR: $DL_DIR
SSTATE_DIR: $SSTATE_DIR
Git revision: $(git -C "$BUILD_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "Artifacts staged at $OUT_DIR"
