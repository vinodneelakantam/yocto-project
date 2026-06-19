#!/usr/bin/env bash
set -euo pipefail

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

REQUIRED_CMDS=(
  gawk
  wget
  git
  unzip
  gcc
  chrpath
  socat
  cpio
  python3
  pip3
  xz
  ping
  xterm
  rsync
  file
  lz4c
  zstd
  pzstd
)

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

echo "Sanity check passed: packages and required host tools are present."
