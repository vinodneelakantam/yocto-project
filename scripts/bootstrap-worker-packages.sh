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
HOST_REQUIREMENTS_LIB="$SCRIPT_DIR/lib/host-requirements.sh"

if [[ ! -f "$HOST_REQUIREMENTS_LIB" ]]; then
  echo "ERROR: Missing host requirements library: $HOST_REQUIREMENTS_LIB"
  exit 1
fi

# shellcheck disable=SC1090
source "$HOST_REQUIREMENTS_LIB"

DEBIAN_FRONTEND=noninteractive
PKGS=("${YOCTO_HOST_PACKAGES[@]}")

echo "Installing worker packages required for Yocto builds..."
$SUDO apt-get update -y
$SUDO apt-get install -y "${PKGS[@]}"

ensure_en_us_utf8_locale() {
  if has_en_us_utf8_locale; then
    return 0
  fi

  echo "en_US.UTF-8 locale not found; generating it..."
  if [[ ! -f /etc/locale.gen ]]; then
    echo "ERROR: /etc/locale.gen not found; cannot generate locale."
    echo "Install and configure locales package, then run: sudo locale-gen en_US.UTF-8"
    exit 1
  fi

  # Ensure locale-gen input contains en_US.UTF-8.
  if ! grep -Eq '^[[:space:]]*en_US\.UTF-8[[:space:]]+UTF-8' /etc/locale.gen; then
    if grep -Eq '^[[:space:]]*#[[:space:]]*en_US\.UTF-8[[:space:]]+UTF-8' /etc/locale.gen; then
      $SUDO sed -i -E 's/^[[:space:]]*#[[:space:]]*(en_US\.UTF-8[[:space:]]+UTF-8)/\1/' /etc/locale.gen
    else
      echo 'en_US.UTF-8 UTF-8' | $SUDO tee -a /etc/locale.gen >/dev/null
    fi
  fi

  if command -v locale-gen >/dev/null 2>&1; then
    $SUDO locale-gen en_US.UTF-8
  else
    echo "ERROR: locale-gen command not found after installing locales package."
    exit 1
  fi

  if command -v update-locale >/dev/null 2>&1; then
    $SUDO update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 || true
  fi

  if ! has_en_us_utf8_locale; then
    echo "ERROR: Failed to provision en_US.UTF-8 locale."
    exit 1
  fi
}

ensure_en_us_utf8_locale

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

# Install Bazelisk (pinned Bazel launcher) so every worker/devcontainer has a
# deterministic Bazel for the SDV applications under apps/ (see
# docs/sdv-bazel-app.md).  Bazelisk reads .bazelversion to pick the exact Bazel
# release, keeping the inner (dev) and outer (Yocto) build loops in sync.
BAZELISK_VERSION="${BAZELISK_VERSION:-v1.22.1}"
BAZELISK_INSTALL_PATH="${BAZELISK_INSTALL_PATH:-/usr/local/bin/bazelisk}"
BAZELISK_REQUIRE_CHECKSUM="${BAZELISK_REQUIRE_CHECKSUM:-false}"
if command -v bazelisk >/dev/null 2>&1 || command -v bazel >/dev/null 2>&1; then
  echo "Bazel/Bazelisk already present; skipping Bazelisk install."
else
  case "$(uname -m)" in
    x86_64|amd64) bazelisk_arch="amd64" ;;
    aarch64|arm64) bazelisk_arch="arm64" ;;
    *) bazelisk_arch="" ;;
  esac

  if [[ -z "$bazelisk_arch" ]]; then
    echo "WARNING: Unsupported architecture '$(uname -m)' for Bazelisk; skipping."
  else
    bazelisk_url="https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-${bazelisk_arch}"
    bazelisk_sha_url="${bazelisk_url}.sha256"
    echo "Installing Bazelisk ${BAZELISK_VERSION} (${bazelisk_arch}) from ${bazelisk_url}..."
    tmp_bazelisk="$(mktemp)"
    tmp_bazelisk_sha="$(mktemp)"

    download_file() {
      local url="$1"
      local output="$2"
      if command -v wget >/dev/null 2>&1 && wget -q --tries=3 --timeout=20 -O "$output" "$url"; then
        return 0
      fi
      if command -v curl >/dev/null 2>&1 && curl -fsSL --retry 3 --connect-timeout 20 "$url" -o "$output"; then
        return 0
      fi
      return 1
    }

    if download_file "$bazelisk_url" "$tmp_bazelisk"; then
      install_bazelisk=true
      if download_file "$bazelisk_sha_url" "$tmp_bazelisk_sha"; then
        expected_sha="$(awk '{print $1}' "$tmp_bazelisk_sha")"
        actual_sha="$(sha256sum "$tmp_bazelisk" | awk '{print $1}')"
        if [[ "$expected_sha" != "$actual_sha" ]]; then
          echo "WARNING: Bazelisk checksum mismatch; skipping install."
          install_bazelisk=false
        fi
      else
        if [[ "$BAZELISK_REQUIRE_CHECKSUM" == "true" ]]; then
          echo "WARNING: Bazelisk checksum file unavailable and BAZELISK_REQUIRE_CHECKSUM=true; skipping install."
          install_bazelisk=false
        else
          echo "WARNING: Bazelisk checksum file unavailable for ${BAZELISK_VERSION}; installing without checksum verification."
        fi
      fi

      if [[ "$install_bazelisk" == "true" ]]; then
        $SUDO install -m 0755 "$tmp_bazelisk" "$BAZELISK_INSTALL_PATH"
        # Provide a `bazel` alias so tools that call `bazel` resolve to Bazelisk.
        if ! command -v bazel >/dev/null 2>&1; then
          $SUDO ln -sf "$BAZELISK_INSTALL_PATH" "$(dirname "$BAZELISK_INSTALL_PATH")/bazel"
        fi
      fi
    else
      echo "WARNING: Failed to download Bazelisk; SDV Bazel builds will be unavailable until it is installed."
    fi
    rm -f "$tmp_bazelisk" "$tmp_bazelisk_sha"
  fi
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
