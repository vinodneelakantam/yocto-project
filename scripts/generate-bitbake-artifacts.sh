#!/usr/bin/env bash
set -euo pipefail

IMAGE_TARGET="${1:-core-image-minimal}"
OUT_BASE_DIR="${2:-out/bitbake-artifacts}"
RUN_TASKEXP_UI="${RUN_TASKEXP_UI:-false}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POKY_INIT_SCRIPT="$ROOT_DIR/sources/poky/oe-init-build-env"
BUILD_DIR="$ROOT_DIR/build"
VIS_SCRIPT="$ROOT_DIR/scripts/visualize-bitbake-log.py"

if [[ ! -f "$POKY_INIT_SCRIPT" ]]; then
  echo "[artifacts] Missing poky init script: $POKY_INIT_SCRIPT"
  exit 1
fi

if [[ ! -x "$VIS_SCRIPT" ]]; then
  echo "[artifacts] Missing executable visualization script: $VIS_SCRIPT"
  exit 1
fi

STAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_DIR="$ROOT_DIR/$OUT_BASE_DIR/$STAMP"
mkdir -p "$OUT_DIR"

# `oe-init-build-env` references optional env vars that may be unset.
nounset_was_set=0
if [[ -o nounset ]]; then
  nounset_was_set=1
  set +u
fi
# shellcheck disable=SC1091
source "$POKY_INIT_SCRIPT" "$BUILD_DIR" >/dev/null
if [[ "$nounset_was_set" -eq 1 ]]; then
  set -u
fi

echo "[artifacts] Generating BitBake dependency graphs for target: $IMAGE_TARGET"
bitbake -g "$IMAGE_TARGET" >/dev/null

for dotf in task-depends.dot pn-depends.dot; do
  if [[ -f "$BUILD_DIR/$dotf" ]]; then
    cp "$BUILD_DIR/$dotf" "$OUT_DIR/$dotf"
  fi
done

if command -v dot >/dev/null 2>&1; then
  [[ -f "$OUT_DIR/task-depends.dot" ]] && dot -Tsvg "$OUT_DIR/task-depends.dot" -o "$OUT_DIR/task-depends.svg" || true
  [[ -f "$OUT_DIR/pn-depends.dot" ]] && dot -Tsvg "$OUT_DIR/pn-depends.dot" -o "$OUT_DIR/pn-depends.svg" || true
else
  echo "[artifacts] Graphviz 'dot' not found; DOT files copied without SVG rendering."
fi

LATEST_LOG="$(find "$BUILD_DIR/tmp/log/cooker" -type f -name '*.log' 2>/dev/null | sort | tail -n 1 || true)"
if [[ -n "$LATEST_LOG" ]]; then
  LOG_OUT_DIR="$OUT_DIR/log-visualization"
  echo "[artifacts] Generating cooker-log visualization from: $LATEST_LOG"
  "$VIS_SCRIPT" "$LATEST_LOG" --out-dir "$LOG_OUT_DIR" --dot-dir "$OUT_DIR" >/dev/null
else
  echo "[artifacts] WARNING: No cooker log found under $BUILD_DIR/tmp/log/cooker"
fi

if [[ "$RUN_TASKEXP_UI" == "true" ]]; then
  if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo "[artifacts] Launching interactive Task Explorer UI..."
    bitbake -u taskexp "$IMAGE_TARGET"
  else
    echo "[artifacts] RUN_TASKEXP_UI=true but no graphical display detected; skipping taskexp UI launch."
  fi
fi

cat > "$OUT_DIR/README.txt" <<EOF
BitBake artifact bundle

Target: $IMAGE_TARGET
Generated: $STAMP

Taskexp-related artifacts (from bitbake -g):
- task-depends.dot
- pn-depends.dot
- task-depends.svg (if Graphviz dot available)
- pn-depends.svg (if Graphviz dot available)

Python log visualization artifacts:
- log-visualization/report.html
- log-visualization/tasks.csv
- log-visualization/recipe_stage_summary.csv
- log-visualization/stage_summary.csv

Optional UI launch:
- Set RUN_TASKEXP_UI=true to also run: bitbake -u taskexp $IMAGE_TARGET
EOF

echo "[artifacts] Bundle ready: $OUT_DIR"
