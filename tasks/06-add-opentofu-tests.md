# Task 06: Add OpenTofu Tests

## Objective

Test catalog validation, module wiring, repository defaults, and public-only
ruleset behavior without credentials or remote resources.

## Prerequisites

- Tasks 03 through 05 are complete.

## Required Work

1. Add native `tofu test` coverage with mocked GitHub provider behavior where possible.
2. Test one public repository and one private repository.
3. Assert safe repository defaults: no wiki, no discussions, merge policy, auto-merge, head-branch deletion, archival behavior, and lifecycle protection.
4. Assert public repositories receive the default-branch ruleset and private repositories do not while the account is on GitHub Free.
5. Assert invalid names, duplicate names, invalid visibility, invalid topics, and prohibited catalog combinations fail.
6. Assert expected module outputs and stable root-module wiring.
7. Add regression tests for every provider limitation or implementation bug discovered during the pilot.

## Acceptance Criteria

- Tests run without `GITHUB_TOKEN`.
- Tests do not call GitHub or require a state backend.
- Tests cover project policy and module behavior, not provider internals.
- Test names explain the intended policy.

## Validation

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
tofu test
```

## Implementation Decisions And Verification

Implementation complete; local validation passed on 2026-09-30 with OpenTofu
1.12.6 and GitHub provider 6.13.0. `tofu init -backend=false` used a dedicated
temporary `TF_DATA_DIR`; `tofu test` ran with `GITHUB_TOKEN` unset. All test
runs use a mocked GitHub provider and `command = plan`; no GitHub API or remote
state backend was used.

- Added plan-only rejection cases for invalid catalog keys and names, names over
  100 characters, duplicate names, unsupported visibility, malformed or
  oversized topics, more than 20 topics, non-HTTPS homepages, unjustified
  feature overrides, and synthetic credential assignments. Valid boundary
  lengths and justified feature overrides are also covered.
- Expanded root wiring checks for empty and populated catalogs, stable-key
  outputs, fixed defaults, and feature override propagation. Existing module
  tests cover repository metadata and safe settings, auto-merge, Dependabot,
  archive behavior, full public ruleset behavior, and private ruleset omission.
- Added a source regression assertion that repository and ruleset resources
  retain literal `prevent_destroy = true`. A stateful destroy attempt is not a
  routine test: lifecycle protection blocked both planning the destroy and
  cleanup in the prior mocked probe. Actual destructive behavior is therefore
  covered by the required lifecycle declaration and the reviewed plan process.
- The suite passes 18 runs. OpenTofu emits the previously documented provider
  deprecation warning for `github_repository.default_branch`; changing that
  implementation is outside this task.

Deployment and live GitHub behavior have not been performed or verified.

## Pending Extension: Tasks 07a And 07b

Retain the credential-free, mocked `tofu test` suite and completed history above.
Task 07a adds plan-only cases for zero/multiple environments, stable wiring,
protection and branch/tag rules, variables, reference validation, unsupported
capabilities and lifecycle/weakening review. Task 07b adds synthetic-only tests
for the compatibility gate, missing/inaccessible references, fail-closed errors,
rotation and saved plans, and canary absence from state, plans, logs and artifacts.
Inspect new mocks, aliases and helpers; no real GitHub or 1Password credentials
may be required. Record gaps in ephemeral/write-only test support rather than
claiming mocks prove the providers safe. This coverage remains pending.

## Out Of Scope

- Testing actual GitHub API behavior in every pull request.
