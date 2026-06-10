---
name: repo-skill-guidelines
description: "Repository intent and standards for authoring SKILL.md files for a GitHub-centric Yocto workflow. Use when creating or reviewing skills in this repo."
---

# Repository Aim

This repository is focused on defining, refining, and validating reusable agent skills for a GitHub-first Yocto workflow.

Primary outcomes:
- Convert repeated Yocto workflows into consistent, executable SKILL.md files
- Keep GitHub as the control and visibility layer
- Treat external compute as the execution layer for heavy builds
- Standardize security practices (signing, OTA integrity, hardening)
- Build a maintainable catalog of workspace-scoped skills

## Workflow Context

Expected operating model in this repo:
- Development in GitHub/Codespaces or remote editor
- Push-driven orchestration with GitHub Actions
- Remote build execution on VPS or equivalent compute
- Artifact publishing and traceability back in GitHub

## Definition Of Done For A Skill

- Purpose is explicit and outcome-focused
- Inputs are clear and minimal
- Workflow is step-by-step with at least one branch/decision point
- Quality checks exist and are measurable
- Security checks are included when relevant (signing, integrity, rollback safety)
- Resource assumptions are explicit (local vs remote build execution)
- Save path is workspace skill location
- Frontmatter is valid YAML with meaningful `name` and `description`

## Authoring Principles

1. Outcome first
- State what the skill produces before explaining how it works.

2. Actionable steps
- Prefer imperative, concrete steps over abstract guidance.

3. Branch-aware
- Include if/then handling for common forks and failures.

4. Verifiable quality
- Add checks that can fail and trigger corrective action.

5. Reusable language
- Remove one-off project noise; preserve reusable process logic.

6. GitHub-centric structure
- Keep workflow visibility in GitHub (commits, actions, artifacts, status).

7. Compute-aware design
- Avoid assuming heavy builds run on GitHub-hosted environments.

8. Security by default
- For image and update workflows, require integrity and rollback considerations.

## Required Structure For New SKILL.md

- Frontmatter
- What this produces
- Inputs
- Assumptions and environment
- Workflow
- Decision points
- Completion checks
- Example prompts

## Preferred Skill Domains

- Yocto layer and recipe change workflow
- CI orchestration and remote build trigger workflow
- Artifact collection, naming, and release workflow
- Binary signing and verification workflow
- OTA generation, validation, and rollback workflow
- BSP hardening and security baseline workflow

## Storage Convention

- Canonical location: `.github/skills/<skill-name>/SKILL.md`
- Root-level drafts are acceptable during iteration, then move to canonical path.

## Review Checklist

- Description includes trigger phrases users are likely to type
- At least one failure branch includes recovery steps
- Completion checks can be validated with evidence (logs, artifacts, status)
- Skill does not hardcode machine-specific paths or secrets

