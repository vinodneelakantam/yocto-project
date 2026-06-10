#!/usr/bin/env bash
set -euo pipefail

# Installs GitHub CLI from official GitHub release packages.
# Artifacts are cached in .tmp/, executable is placed in .local/bin/gh.

GH_VERSION="${GH_VERSION:-2.93.0}"
ARCH="${ARCH:-amd64}"
OS="${OS:-linux}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$ROOT_DIR/.tmp"
LOCAL_BIN_DIR="$ROOT_DIR/.local/bin"

TARBALL="gh_${GH_VERSION}_${OS}_${ARCH}.tar.gz"
CHECKSUMS="gh_${GH_VERSION}_checksums.txt"
RELEASE_BASE_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}"

mkdir -p "$TMP_DIR" "$LOCAL_BIN_DIR"

tarball_path="$TMP_DIR/$TARBALL"
checksums_path="$TMP_DIR/$CHECKSUMS"
extract_dir="$TMP_DIR/gh_${GH_VERSION}_${OS}_${ARCH}"

if [[ ! -f "$tarball_path" ]]; then
  curl -fsSL "$RELEASE_BASE_URL/$TARBALL" -o "$tarball_path"
fi

if [[ ! -f "$checksums_path" ]]; then
  curl -fsSL "$RELEASE_BASE_URL/$CHECKSUMS" -o "$checksums_path"
fi

expected_sha="$(awk -v f="$TARBALL" '$2 == f {print $1}' "$checksums_path")"
if [[ -z "$expected_sha" ]]; then
  echo "Failed to locate checksum for $TARBALL in $CHECKSUMS"
  exit 1
fi

actual_sha="$(sha256sum "$tarball_path" | awk '{print $1}')"
if [[ "$actual_sha" != "$expected_sha" ]]; then
  echo "Checksum verification failed for $TARBALL"
  echo "Expected: $expected_sha"
  echo "Actual:   $actual_sha"
  exit 1
fi

rm -rf "$extract_dir"
tar -xzf "$tarball_path" -C "$TMP_DIR"
install -m 0755 "$extract_dir/bin/gh" "$LOCAL_BIN_DIR/gh"

echo "$LOCAL_BIN_DIR/gh"