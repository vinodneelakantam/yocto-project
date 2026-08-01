#!/usr/bin/env bash
# Convenience wrapper around the local Bazel remote cache (docker compose).
#
# Usage: scripts/bazel-remote-cache.sh {up|down|status|logs}
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/infra/bazel-remote/docker-compose.yml"

usage() {
  echo "Usage: $0 {up|down|status|logs}" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

case "$1" in
  up)
    docker compose -f "${COMPOSE_FILE}" up -d
    echo "Bazel remote cache running on grpc://localhost:9092 (status: http://localhost:9090/status)"
    echo "Build with: bazel build --config=remote-cache //apps/..."
    ;;
  down)
    docker compose -f "${COMPOSE_FILE}" down
    ;;
  status)
    docker compose -f "${COMPOSE_FILE}" ps
    ;;
  logs)
    docker compose -f "${COMPOSE_FILE}" logs -f
    ;;
  *)
    usage
    ;;
esac
