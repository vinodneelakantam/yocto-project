# Diagram Gallery

This page collects every repository diagram PNG in one place with short
explanations, so documentation is inclusive and visually complete.

Use this page when you want a quick visual understanding before diving into
the detailed implementation documents.

## At a Glance

| Diagram | What It Helps Explain |
|---|---|
| Architecture overview | System boundaries and major responsibilities |
| Remote CI pipeline | End-to-end GitHub-hosted build flow |
| GHCR image lifecycle | How the reusable build image is produced/consumed |
| Cache strategy | Why rebuilds are faster over time |
| Repository collaboration | How contributors and automation interact |

## Architecture Overview

Path: `docs/diagrams/architecture-overview.png`

Shows the top-level separation between coordination (GitHub) and compute
(GHCR container and workers), including where artifacts and cache layers fit.

Use this when onboarding a new contributor or explaining the platform model.

![Architecture overview (top-level)](docs/diagrams/architecture-overview.png)

## Remote CI Pipeline

Path: `docs/diagrams/ci-remote-pipeline.png`

Step-by-step pipeline for the GitHub-hosted remote build path: trigger, cache
restore, submodule init, containerized build, cache save, and artifact upload.

Use this when debugging CI flow or explaining where failures usually occur.

![Remote CI pipeline (step-by-step)](docs/diagrams/ci-remote-pipeline.png)

## GHCR Image Lifecycle

Path: `docs/diagrams/ghcr-image-lifecycle.png`

Explains how the Yocto build image is rebuilt, tagged, cached, and consumed by
the build workflow.

Use this when changing `.devcontainer/Dockerfile` or GHCR publishing behavior.

![GHCR image lifecycle](docs/diagrams/ghcr-image-lifecycle.png)

## Cache Strategy

Path: `docs/diagrams/cache-layers.png`

Shows the three cache tiers (Docker layers, downloads, sstate) and how they
reduce rebuild time across CI and local environments.

Use this when discussing build performance and cache-key strategy.

![Cache strategy (three tiers)](docs/diagrams/cache-layers.png)

## Repository Collaboration Diagram

Path: `docs/diagrams/repo-collaboration-block-diagram-v3.png`

Visual map of repository collaboration flow, highlighting contributors,
workflow automation, and shared outputs.

Use this when presenting team workflow, ownership, and handoff points.

![Repository collaboration block diagram v3](docs/diagrams/repo-collaboration-block-diagram-v3.png)