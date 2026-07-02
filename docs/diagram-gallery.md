# Diagram Gallery

This page collects every repository diagram PNG in one place with short
explanations, so documentation is inclusive and visually complete.

## Architecture Overview

Path: `docs/diagrams/architecture-overview.png`

Shows the top-level separation between coordination (GitHub) and compute
(GHCR container and workers), including where artifacts and cache layers fit.

![Architecture overview (top-level)](docs/diagrams/architecture-overview.png)

## Remote CI Pipeline

Path: `docs/diagrams/ci-remote-pipeline.png`

Step-by-step pipeline for the GitHub-hosted remote build path: trigger, cache
restore, submodule init, containerized build, cache save, and artifact upload.

![Remote CI pipeline (step-by-step)](docs/diagrams/ci-remote-pipeline.png)

## GHCR Image Lifecycle

Path: `docs/diagrams/ghcr-image-lifecycle.png`

Explains how the Yocto build image is rebuilt, tagged, cached, and consumed by
the build workflow.

![GHCR image lifecycle](docs/diagrams/ghcr-image-lifecycle.png)

## Cache Strategy

Path: `docs/diagrams/cache-layers.png`

Shows the three cache tiers (Docker layers, downloads, sstate) and how they
reduce rebuild time across CI and local environments.

![Cache strategy (three tiers)](docs/diagrams/cache-layers.png)

## Repository Collaboration Diagram

Path: `docs/diagrams/repo-collaboration-block-diagram-v3.png`

Visual map of repository collaboration flow, highlighting contributors,
workflow automation, and shared outputs.

![Repository collaboration block diagram v3](docs/diagrams/repo-collaboration-block-diagram-v3.png)