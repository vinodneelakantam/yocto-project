#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
AWS Spot worker automation is not implemented in this repository yet.

This placeholder exists to keep the interface visible for future work:
- Provision spot worker
- Bootstrap packages and source checkout
- Execute remote-build.sh
- Collect and upload artifacts
- Tear down worker

See docs/cloud/aws-spot-worker-plan.md for implementation plan.
EOF

exit 0
