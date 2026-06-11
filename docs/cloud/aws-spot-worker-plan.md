# AWS Spot Worker Plan (Placeholder)

## Status

Planned placeholder for cloud worker automation. Current production path remains VPS-backed remote build.

## Goal

Use AWS Spot instances as cost-optimized ephemeral build workers while GitHub Actions remains the frontend for logs and artifacts.

## Intended Flow

1. GitHub Actions requests a Spot worker.
2. Worker bootstraps required packages and source checkout.
3. Worker runs scripts/remote-build.sh.
4. Artifacts are copied back and published in GitHub Actions.
5. Worker is terminated.

## Required Future Work

- IAM policy and least-privilege credentials model.
- Spot request and interruption handling.
- Cache persistence for downloads/sstate across workers.
- Optional fallback to VPS or on-demand instance.

## Inputs To Standardize

- AMI/OS image
- Instance type list
- VPC/subnet/security group
- SSH strategy or SSM strategy
- Cache bucket/storage location
