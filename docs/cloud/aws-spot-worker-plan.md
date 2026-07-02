# AWS Spot Worker Plan

## Status

Current production backend is VPS-based. AWS Spot worker automation is planned
and not yet implemented end-to-end.

## Objective

Run Yocto builds on ephemeral AWS Spot workers while preserving the existing
GitHub workflow interface, logs, and artifact behavior.

## Target Contract

From GitHub workflow perspective, cloud backend must preserve:
- same input shape (`image`, `clean`, backend selector),
- same output paths (`out/`, `out/build-summary.txt`),
- same failure visibility and artifact publication behavior.

## Planned Execution Flow

1. Workflow requests Spot capacity from approved instance pools.
2. Worker is provisioned with baseline dependencies and repository checkout.
3. Worker executes `scripts/remote-build.sh`.
4. Outputs are uploaded back through the workflow.
5. Worker is terminated on success and on failure paths.

## Milestones

1. Define backend abstraction and interface contract.
2. Implement Spot provisioning and teardown path.
3. Add interruption handling and fallback policy.
4. Add cache persistence strategy for `downloads` and `sstate-cache`.
5. Validate parity against VPS backend on at least one stable image target.

## Required Decisions

- IAM model (least privilege, short-lived credentials).
- Access path (SSH vs SSM).
- Network boundary (VPC/subnets/security groups).
- Cache storage backend and retention policy.
- Fallback behavior when Spot capacity is unavailable.

## Exit Criteria

- Successful build run from GitHub using spot backend.
- Verified teardown on cancellation and failure.
- Artifact parity with VPS flow.
- Documented operational runbook for interruption and fallback.
