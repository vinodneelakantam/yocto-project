#!/usr/bin/env bash
# Print the Bazel targets affected by changes against a base ref, using
# `bazel query`'s reverse-dependency graph (rdeps).
#
# This is the "independent builds" payoff of a cleanly partitioned Bazel
# graph (libs/vss-common, apps/*, tools/*): only targets that actually depend
# on what changed need to be rebuilt/retested, not the whole tree. See
# docs/bazel-build-system.md#independent-builds--change-impact-analysis.
#
# Usage:
#   scripts/bazel-affected-targets.sh [base-ref]   # default base-ref: origin/main
set -euo pipefail

BASE_REF="${1:-origin/main}"

BAZEL_BIN="$(command -v bazelisk || command -v bazel || true)"
if [[ -z "${BAZEL_BIN}" ]]; then
  echo "bazel/bazelisk not found on PATH." >&2
  exit 1
fi

mapfile -t changed_files < <(git diff --name-only "${BASE_REF}...HEAD" -- \
  '*.bazel' '*.bzl' 'apps/**' 'libs/**' 'tools/**' 'MODULE.bazel' 2>/dev/null || true)

if [[ ${#changed_files[@]} -eq 0 ]]; then
  echo "No Bazel-relevant file changes detected against ${BASE_REF}." >&2
  exit 0
fi

echo "Changed files (vs ${BASE_REF}):" >&2
printf '  %s\n' "${changed_files[@]}" >&2

# Translate changed files into their owning packages, expanded to every
# target in that package (`//pkg/...`).
declare -A seen_pkgs=()
pkg_targets=()
for file in "${changed_files[@]}"; do
  pkg="$(dirname "${file}")"
  [[ -n "${seen_pkgs[${pkg}]:-}" ]] && continue
  seen_pkgs["${pkg}"]=1
  pkg_targets+=("//${pkg}/...")
done

query="rdeps(//..., set(${pkg_targets[*]}))"

echo "" >&2
echo "Affected targets:" >&2
"${BAZEL_BIN}" query "${query}" 2>/dev/null
