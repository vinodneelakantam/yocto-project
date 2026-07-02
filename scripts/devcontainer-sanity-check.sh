#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_REQUIREMENTS_LIB="$SCRIPT_DIR/lib/host-requirements.sh"

if [[ ! -f "$HOST_REQUIREMENTS_LIB" ]]; then
  echo "ERROR: Missing host requirements library: $HOST_REQUIREMENTS_LIB"
  exit 1
fi

# shellcheck disable=SC1090
source "$HOST_REQUIREMENTS_LIB"

PKGS=("${YOCTO_HOST_PACKAGES[@]}")
REQUIRED_CMDS=("${YOCTO_REQUIRED_CMDS[@]}")

if ! command -v dpkg-query >/dev/null 2>&1; then
  echo "ERROR: dpkg-query is unavailable; cannot validate package installation."
  exit 1
fi

missing_pkgs=()
for pkg in "${PKGS[@]}"; do
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    missing_pkgs+=("$pkg")
  fi
done

if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
  echo "ERROR: Missing expected packages: ${missing_pkgs[*]}"
  echo "Run: sudo apt-get update && sudo apt-get install -y ${missing_pkgs[*]}"
  exit 1
fi

missing_cmds=()
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing_cmds+=("$cmd")
  fi
done

if [[ ${#missing_cmds[@]} -gt 0 ]]; then
  echo "ERROR: Missing expected commands in PATH: ${missing_cmds[*]}"
  exit 1
fi

if ! has_en_us_utf8_locale; then
  echo "ERROR: Missing required locale en_US.UTF-8."
  echo "Run: ./scripts/bootstrap-worker-packages.sh"
  echo "Or manually: sudo apt-get install -y locales && sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"
  exit 1
fi

echo "Sanity check passed: packages and required host tools are present."

# Soft check: Bazel/Bazelisk powers the SDV applications under apps/.  It is
# installed by bootstrap-worker-packages.sh from a network release, so warn
# (rather than fail) when it is absent — e.g. on offline bootstraps.
if command -v bazel >/dev/null 2>&1 || command -v bazelisk >/dev/null 2>&1; then
  echo "Bazel/Bazelisk found: SDV Bazel builds are available."
else
  echo "WARNING: bazel/bazelisk not found in PATH."
  echo "         SDV application builds (apps/) require it; install via scripts/bootstrap-worker-packages.sh."
fi
