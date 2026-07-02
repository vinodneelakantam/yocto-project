#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_file="${1:-${repo_root}/out/docs-html/index.html}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to build HTML docs" >&2
  exit 1
fi

deps_dir="${repo_root}/.tmp/docs-html-deps"
deps_pythonpath="${deps_dir}${PYTHONPATH:+:${PYTHONPATH}}"

if ! PYTHONPATH="${deps_pythonpath}" python3 -c "import markdown" >/dev/null 2>&1; then
  echo "Python package 'markdown' not found. Installing locally in ${deps_dir}..."
  mkdir -p "${deps_dir}"
  python3 -m pip install --quiet --disable-pip-version-check --target "${deps_dir}" markdown
fi

export PYTHONPATH="${deps_pythonpath}"

python3 "${repo_root}/scripts/render-docs-html.py" \
  --root "${repo_root}" \
  --output "${output_file}"

echo "Documentation HTML available at ${output_file}"