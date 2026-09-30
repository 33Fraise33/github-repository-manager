# Task 07: Add CI Validation And Plan Workflow

## Objective

Add a pull-request workflow that validates generic OpenTofu repository
infrastructure and, where safe, produces a speculative plan without applying
changes.

## Prerequisites

- Tasks 01 through 06 are complete.

## Required Work

1. Create a GitHub Actions workflow for pull requests and pushes to `main`.
2. Run formatting, backend-disabled initialization, validation, OpenTofu tests, and any selected maintained lint or security tools.
3. Pin every third-party action to a full commit SHA and use least-privilege workflow permissions.
4. Run authenticated speculative plans only for trusted same-repository events. Never expose `GITHUB_TOKEN` to fork pull requests.
5. Use workflow concurrency to cancel obsolete validation runs without cancelling an active apply workflow.
6. Publish a concise sanitized plan summary. Do not publish credentials, state, or a reusable binary plan artifact.
7. Configure the workflow token as read-only unless a step demonstrably needs more.

## Acceptance Criteria

- Pull requests validate repository infrastructure without a real apply.
- Forked pull requests never receive the PAT.
- Authentication failures are useful but do not leak credential details.
- All actions are immutable-pinned.

## Validation

- Run actionlint if included.
- Review workflow permissions and event conditions manually.
- Trigger a same-repository test pull request and a fork-equivalent test where feasible.

## Out Of Scope

- Applying OpenTofu from CI.
- Repository content validation.

## Implementation Decisions And Verification

- Added `.github/workflows/ci.yml` with immutable action pins and credential-free
  formatting, backend-disabled initialization, validation, and mocked tests on
  pull requests and pushes to `main`.
- Added an opt-in trusted speculative-plan job. It only admits `main` pushes and
  same-repository non-Dependabot PRs and requires approval from the protected
  `repository-plan` environment. The opt-in variable is off unless explicitly
  set to `true`. Its documentation requires setup and operator approval for the
  specific R2 bucket/state key before it can access remote state.
- The trusted plan validates the GitHub identity before remote backend
  initialization using an isolated backend-free OpenTofu root, keeps PAT and R2
  secrets out of validation, initializes the remote backend once with a
  temporary HCL config and reuses the same `TF_DATA_DIR` for planning, uses
  remote locking, and reports the exact PR head commit in the summary.
- Pull requests are limited to `main`; validation concurrency cannot cancel a
  trusted plan. The summary helper `scripts/summarize-tofu-plan.py` sanitizes
  output and rejects deletion/replacement actions; name, visibility, and archive
  attribute differences are shown for operator review.
- Local verification passed with OpenTofu 1.12.6: `tofu fmt -check -recursive`,
  `tofu init -backend=false -lockfile=readonly` (dedicated temporary
  `TF_DATA_DIR`), `tofu validate`, `tofu test` (18 passed), YAML parsing via
  Ruby Psych, and `git diff --check`. The test suite reports the existing
  `github_repository.default_branch` provider deprecation warning documented in
  Task 06.
- `actionlint` could not be run because it is not installed in this
  environment. Python YAML parsing was also unavailable (`PyYAML` is not
  installed); Ruby Psych successfully parsed the workflow YAML.
- Plan summary fixtures passed: a synthetic attribute update is summarized
  successfully, and a synthetic replacement returns failure.
- Live same-repository and fork-equivalent Actions runs: not performed. No
  remote is configured in this checkout.
