#!/usr/bin/env bash

# Shared host requirements for Yocto developer and worker environments.

YOCTO_HOST_PACKAGES=(
  gawk
  wget
  curl
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
  locales
)

YOCTO_REQUIRED_CMDS=(
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
  locale
)

has_en_us_utf8_locale() {
  locale -a 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -Eq '^en_us\.utf-?8$'
}

export_best_utf8_locale() {
  if has_en_us_utf8_locale; then
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    return 0
  fi

  if locale -a 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -q '^c\.utf-8$'; then
    export LANG="C.UTF-8"
    export LC_ALL="C.UTF-8"
    return 0
  fi

  return 1
}