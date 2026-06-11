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
  libegl1-mesa
  libsdl1.2-dev
  xterm
  rsync
)

echo "Installing worker packages required for Yocto builds..."
$SUDO apt-get update -y
$SUDO apt-get install -y "${PKGS[@]}"
