# Jira Development Backlog - Yocto GitHub-First Build Platform

## How to Use This File

- Create one Epic in Jira for each Epic section below.
- Create one Story or Task in Jira for each ticket section.
- Copy the Description and Acceptance Criteria directly into Jira fields.
- Use Dependencies to sequence implementation.

## Recommended Jira Labels

- yocto
- github-actions
- external-compute
- aws-spot
- caching
- security
- ota
- portfolio

## EPIC 1: Platform Foundation And Repository Baseline

### Ticket: PLAT-001
- Type: Story
- Summary: Finalize repository structure and enforce source-of-truth conventions
- Priority: High
- Labels: yocto, platform-foundation
- Description:
  Establish a stable repository baseline so all future automation and builds use a predictable layout. This includes validating the current structure for layers, scripts, docs, workflow definitions, and pinned submodules. Add guardrails that prevent accidental drift in core folders and ensure new contributors understand what belongs in each path.

  Scope:
  - Validate folder structure against architecture intent.
  - Confirm required top-level paths exist and are documented.
  - Add ownership notes for layers, scripts, and workflow files.
  - Define naming conventions for new recipes and app layers.
- Acceptance Criteria:
  - Repository structure is documented and approved.
  - Required paths are present and version controlled.
  - Naming conventions are added to docs.
  - New contributor can identify where to add recipes, apps, and scripts.
- Dependencies: None
- Estimate: 3 story points

### Ticket: PLAT-002
- Type: Task
- Summary: Pin and validate Yocto upstream submodules
- Priority: High
- Labels: yocto, submodules
- Description:
  Ensure pinned versions of upstream sources are reproducible and reviewable. Validate that submodule pointers for poky and meta-openembedded are tracked intentionally and that update workflow is documented.

  Scope:
  - Confirm submodules are initialized recursively in CI and local flow.
  - Document approved branches and update policy.
  - Add validation step to detect uninitialized submodules in build flow.
- Acceptance Criteria:
  - CI fails early if submodules are missing.
  - Approved submodule update process is documented.
  - Submodule state is reproducible on fresh clone.
- Dependencies: PLAT-001
- Estimate: 2 story points

## EPIC 2: GitHub Actions Orchestration And Visibility

### Ticket: CICD-001
- Type: Story
- Summary: Harden remote build orchestration workflow in GitHub Actions
- Priority: High
- Labels: github-actions, orchestration
- Description:
  Stabilize the remote build workflow so GitHub remains the control and visibility frontend while heavy Yocto builds run externally. Improve validation, clearer logs, fail-fast behavior for missing prerequisites, and deterministic artifact handling.

  Scope:
  - Validate required secrets and inputs.
  - Improve step-level logs for sync, build, collect, and upload phases.
  - Add clear status messaging when external compute is unavailable.
  - Ensure artifact naming follows a deterministic pattern.
- Acceptance Criteria:
  - Workflow provides clear failure reasons for missing prerequisites.
  - Artifacts are uploaded consistently for successful builds.
  - Logs are understandable for non-authors.
  - Workflow remains manually triggerable with image and clean inputs.
- Dependencies: PLAT-001, PLAT-002
- Estimate: 5 story points

### Ticket: CICD-002
- Type: Task
- Summary: Add workflow summary output for build metadata
- Priority: Medium
- Labels: github-actions, observability, portfolio
- Description:
  Add a post-build summary in GitHub Actions UI with key build metadata so reviewers can quickly understand what was built without opening full logs.

  Scope:
  - Include target image, clean mode, source revision, and artifact links.
  - Include compute backend used (VPS or cloud worker).
  - Include build duration and result status.
- Acceptance Criteria:
  - Workflow run summary contains key build metadata.
  - Summary is visible in GitHub Actions run page.
  - Summary format is consistent across manual and push triggers.
- Dependencies: CICD-001
- Estimate: 2 story points

## EPIC 3: External Compute Abstraction (VPS And Cloud Spot)

### Ticket: COMP-001
- Type: Story
- Summary: Introduce compute backend abstraction for VPS and AWS Spot workers
- Priority: High
- Labels: external-compute, aws-spot
- Description:
  Replace single-backend assumptions with an abstraction layer that supports multiple worker providers while keeping GitHub Actions as frontend. The workflow should choose a backend based on configuration and execute the same build contract.

  Scope:
  - Define compute backend interface (provision, prepare, build, collect, teardown).
  - Implement current VPS backend under the interface.
  - Add placeholder or initial AWS Spot backend implementation.
  - Keep outputs and logs identical from GitHub perspective.
- Acceptance Criteria:
  - Build orchestration can select backend by configuration.
  - VPS path continues to work.
  - Cloud worker path can execute end-to-end in a test run.
  - Artifact contract remains unchanged.
- Dependencies: CICD-001
- Estimate: 8 story points

### Ticket: COMP-002
- Type: Story
- Summary: Implement AWS Spot instance lifecycle automation for build workers
- Priority: High
- Labels: aws-spot, cost-optimization
- Description:
  Implement worker lifecycle on AWS Spot to reduce cost for heavy Yocto builds. Workers should be ephemeral and automatically terminated after build completion or failure.

  Scope:
  - Provision Spot instance with required size/profile.
  - Bootstrap worker packages and build prerequisites.
  - Checkout codebase and submodules on worker.
  - Run build and collect outputs.
  - Terminate worker safely and reliably.
- Acceptance Criteria:
  - Spot worker is provisioned and terminated automatically.
  - Build executes successfully on Spot worker.
  - Failure paths still terminate worker.
  - Cost tags are applied for reporting.
- Dependencies: COMP-001
- Estimate: 13 story points

### Ticket: COMP-003
- Type: Task
- Summary: Add fallback policy when Spot capacity is unavailable
- Priority: Medium
- Labels: aws-spot, resilience
- Description:
  Define and implement fallback behavior when Spot instances are interrupted or unavailable, while preserving build visibility in GitHub Actions.

  Scope:
  - Retry policy for alternative instance types.
  - Optional fallback to on-demand or VPS.
  - Clear GitHub log annotation for fallback decision.
- Acceptance Criteria:
  - Spot interruption does not leave pipeline in unknown state.
  - Fallback behavior is configurable.
  - GitHub logs show which fallback path was used.
- Dependencies: COMP-002
- Estimate: 5 story points

## EPIC 4: Build Performance, Caching, And Toolchain Management

### Ticket: PERF-001
- Type: Story
- Summary: Implement shared cache strategy for Yocto builds
- Priority: High
- Labels: caching, performance
- Description:
  Reduce rebuild time and cost by standardizing cache usage across external workers. Persist and reuse sstate-cache and downloads directories using a backend suitable for VPS and cloud workers.

  Scope:
  - Define cache paths and retention policy.
  - Implement cache restore and save steps.
  - Protect cache integrity across branches and targets.
  - Add cache hit or miss reporting in build summary.
- Acceptance Criteria:
  - Subsequent builds show measurable runtime reduction.
  - Cache corruption handling is documented.
  - Cache usage is visible in workflow logs.
- Dependencies: CICD-001, COMP-001
- Estimate: 8 story points

### Ticket: PERF-002
- Type: Task
- Summary: Standardize package-based dependency bootstrap for workers
- Priority: High
- Labels: toolchain, reproducibility
- Description:
  Create a deterministic package installation process for compilers and required tools on worker startup. Keep worker images lightweight and reproducible.

  Scope:
  - Define required OS packages and versions.
  - Add bootstrap script for worker setup.
  - Validate tool versions before build starts.
- Acceptance Criteria:
  - Worker bootstrap succeeds from clean instance.
  - Build fails early when required tools are missing.
  - Tooling list is documented and versioned.
- Dependencies: COMP-001
- Estimate: 5 story points

## EPIC 5: Security, Signing, And Supply Chain Controls

### Ticket: SEC-001
- Type: Story
- Summary: Add secure secrets and key handling policy for remote builds
- Priority: High
- Labels: security, secrets
- Description:
  Formalize secret handling for SSH keys, cloud credentials, and future signing keys. Prevent sensitive material from being exposed in logs or repository history.

  Scope:
  - Define secret scopes and rotation policy.
  - Verify workflow masking and safe logging.
  - Document emergency key rotation runbook.
- Acceptance Criteria:
  - Secret handling policy approved and published.
  - CI logs do not expose sensitive values.
  - Rotation process tested once in non-production environment.
- Dependencies: CICD-001
- Estimate: 5 story points

### Ticket: SEC-002
- Type: Story
- Summary: Implement artifact signing and verification pipeline
- Priority: Medium
- Labels: security, signing, supply-chain
- Description:
  Add signing for build outputs and verification metadata so produced artifacts can be trusted before deployment.

  Scope:
  - Sign selected images or manifests.
  - Publish checksums and signature files with artifacts.
  - Add verification instructions for consumers.
- Acceptance Criteria:
  - Signed artifacts are produced in successful builds.
  - Verification instructions are documented and tested.
  - Unsigned or tampered artifacts fail verification.
- Dependencies: SEC-001
- Estimate: 8 story points

## EPIC 6: OTA Readiness And Release Governance

### Ticket: OTA-001
- Type: Story
- Summary: Define OTA-ready image strategy with rollback capability
- Priority: Medium
- Labels: ota, release
- Description:
  Prepare release model for OTA by defining image layout expectations, health checks, and rollback behavior. This ticket focuses on design and validation criteria rather than immediate production rollout.

  Scope:
  - Document A/B update strategy baseline.
  - Define health-check criteria and rollback triggers.
  - Map artifact metadata required for OTA delivery.
- Acceptance Criteria:
  - OTA design document approved.
  - Rollback decision logic is defined.
  - Build outputs include metadata needed by OTA pipeline.
- Dependencies: SEC-002
- Estimate: 8 story points

### Ticket: OTA-002
- Type: Task
- Summary: Add release tagging and artifact retention policy
- Priority: Medium
- Labels: ota, governance
- Description:
  Introduce release hygiene to keep build outputs auditable and manageable over time.

  Scope:
  - Define semantic release/tag strategy.
  - Configure artifact retention by build type.
  - Document promotion path from test to release builds.
- Acceptance Criteria:
  - Release tags are consistent and documented.
  - Retention policy is implemented and visible.
  - Promotion path is documented for team usage.
- Dependencies: CICD-002
- Estimate: 3 story points

## EPIC 7: Portfolio And Developer Experience

### Ticket: DX-001
- Type: Story
- Summary: Publish portfolio-facing build dashboard guidance in docs
- Priority: Medium
- Labels: portfolio, docs
- Description:
  Ensure the repository communicates value clearly to hiring managers and collaborators by documenting where to view builds, artifacts, and evidence of practical Yocto work.

  Scope:
  - Add portfolio navigation section in README.
  - Link architecture and diagram artifacts.
  - Explain where to find successful build proof in GitHub Actions.
- Acceptance Criteria:
  - README includes portfolio-oriented navigation.
  - New visitor can find build outputs in under 2 minutes.
  - Documentation language is clear and non-internal.
- Dependencies: CICD-002
- Estimate: 3 story points

### Ticket: DX-002
- Type: Task
- Summary: Create onboarding checklist for new contributors
- Priority: Low
- Labels: docs, onboarding
- Description:
  Provide a quick start checklist for contributors to reduce setup errors and improve consistency.

  Scope:
  - Required tools and access.
  - Submodule setup and validation.
  - How to trigger and read remote builds.
- Acceptance Criteria:
  - Checklist is added to documentation.
  - A new contributor can run a first build following the checklist.
- Dependencies: PLAT-001, PLAT-002
- Estimate: 2 story points

## Suggested Delivery Phases

### Phase 1: Core Stability
- PLAT-001
- PLAT-002
- CICD-001
- CICD-002

### Phase 2: Cost-Optimized Compute
- COMP-001
- COMP-002
- COMP-003
- PERF-002
- PERF-001

### Phase 3: Security And OTA Readiness
- SEC-001
- SEC-002
- OTA-001
- OTA-002

### Phase 4: Portfolio And Team Scale
- DX-001
- DX-002

## Definition Of Done (Global)

- Code merged to main with review.
- Documentation updated in repository.
- Workflow evidence available in GitHub Actions.
- Rollback or failure behavior defined where relevant.
- Security implications reviewed for infrastructure-facing changes.
