#!/usr/bin/env bash

GH_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GH_HELPER_REPO_ROOT="$(cd "$GH_HELPER_DIR/../.." && pwd)"

resolve_gh_bin() {
  if [[ -n "${GH_BIN:-}" ]]; then
    if command -v "$GH_BIN" >/dev/null 2>&1; then
      command -v "$GH_BIN"
      return 0
    fi
    if [[ -x "$GH_BIN" ]]; then
      printf '%s\n' "$GH_BIN"
      return 0
    fi
  fi

  if command -v gh >/dev/null 2>&1; then
    command -v gh
    return 0
  fi

  if [[ -x "$GH_HELPER_REPO_ROOT/.local/bin/gh" ]]; then
    printf '%s\n' "$GH_HELPER_REPO_ROOT/.local/bin/gh"
    return 0
  fi

  if [[ -x "$GH_HELPER_REPO_ROOT/scripts/github/install-gh-from-github.sh" ]]; then
    "$GH_HELPER_REPO_ROOT/scripts/github/install-gh-from-github.sh"
    return 0
  fi

  return 1
}

require_gh_cli() {
  local gh_bin
  if ! gh_bin="$(resolve_gh_bin)"; then
    echo "GitHub CLI (gh) is required but not found."
    return 1
  fi
  printf '%s\n' "$gh_bin"
}

require_gh_auth() {
  local gh_bin="$1"
  if ! "$gh_bin" auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated. Run: gh auth login"
    return 1
  fi
}