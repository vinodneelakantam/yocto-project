#!/usr/bin/env bash
set -euo pipefail

if [[ "${BOOTSTRAP_PACKAGES:-true}" != "true" ]]; then
  echo "Skipping worker package bootstrap (BOOTSTRAP_PACKAGES=false)."
  exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "apt-get not found; worker package bootstrap skipped."
  exit 0
fi

SUDO=""
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANITY_CHECK_SCRIPT="$SCRIPT_DIR/devcontainer-sanity-check.sh"

DEBIAN_FRONTEND=noninteractive
PKGS=(
  gawk
  wget
  git
  diffstat
  unzip
  texinfo
  gcc
  build-essential
  chrpath
  socat
  cpio
  python3
  python3-pip
  python3-pexpect
  xz-utils
  debianutils
  iputils-ping
  python3-git
  python3-jinja2
  libegl1
  libsdl1.2-dev
  xterm
  rsync
  file
  lz4
  zstd
)

echo "Installing worker packages required for Yocto builds..."
$SUDO apt-get update -y
$SUDO apt-get install -y "${PKGS[@]}"

missing_pkgs=()
for pkg in "${PKGS[@]}"; do
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    missing_pkgs+=("$pkg")
  fi
done

if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
  echo "ERROR: Package bootstrap incomplete. Missing: ${missing_pkgs[*]}"
  exit 1
fi

if ! command -v pzstd >/dev/null 2>&1; then
  echo "ERROR: pzstd is still unavailable after package bootstrap."
  echo "On Debian/Ubuntu, install package: zstd"
  exit 1
fi

if ! command -v lz4c >/dev/null 2>&1; then
  echo "ERROR: lz4c is still unavailable after package bootstrap."
  echo "On Debian/Ubuntu, install package: lz4"
  exit 1
fi

if ! command -v file >/dev/null 2>&1; then
  echo "ERROR: file is still unavailable after package bootstrap."
  echo "On Debian/Ubuntu, install package: file"
  exit 1
fi

if [[ -x "$SANITY_CHECK_SCRIPT" ]]; then
  "$SANITY_CHECK_SCRIPT"
else
  echo "ERROR: sanity check script not found or not executable: $SANITY_CHECK_SCRIPT"
  exit 1
fi
