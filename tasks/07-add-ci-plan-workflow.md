# Task 07: Add CI Validation And Plan Workflow

## Objective

Add a pull-request workflow that validates the OpenTofu project and, where safe, produces a speculative plan without applying changes.

## Prerequisites

- Tasks 01 through 06 are complete.

## Required Work

1. Create a GitHub Actions workflow for pull requests and pushes to `main`.
2. Run formatting, initialization, validation, OpenTofu tests, and any selected maintained lint/security tools.
3. Pin every third-party action to a full commit SHA and use least-privilege workflow permissions.
4. Run authenticated speculative plans only for trusted same-repository events. Never expose `GITHUB_TOKEN` to fork pull requests.
5. Use workflow concurrency to cancel obsolete validation runs without cancelling an active apply workflow.
6. Publish a concise sanitized plan summary. Do not publish credentials, state, or a reusable binary plan artifact.
7. Configure the workflow token as read-only unless a step demonstrably needs more.

## Acceptance Criteria

- Pull requests validate without a real apply.
- Forked pull requests never receive the PAT.
- Authentication failures are useful but do not leak credential details.
- All actions are immutable-pinned.

## Validation

- Run actionlint if included.
- Review workflow permissions and event conditions manually.
- Trigger a same-repository test PR and a fork-equivalent test where feasible.

## Out Of Scope

- Applying OpenTofu from CI.
