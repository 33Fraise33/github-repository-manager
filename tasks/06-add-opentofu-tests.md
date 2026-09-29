# Task 06: Add OpenTofu Tests

## Objective

Test catalog validation, module wiring, and generated repository settings without requiring GitHub credentials or creating remote resources.

## Prerequisites

- Tasks 03 through 05 are complete.

## Required Work

1. Add native `tofu test` coverage with mocked GitHub provider behavior where possible.
2. Test a public role and a private role.
3. Assert safe defaults: no wiki, no discussions, expected merge policy, head-branch deletion, and lifecycle protection.
4. Assert invalid names, duplicate names, invalid visibility, and prohibited catalog combinations fail.
5. Assert expected outputs and template selection behavior.
6. Add regression tests for every provider limitation or implementation bug discovered during the pilot.

## Acceptance Criteria

- Tests run without `GITHUB_TOKEN`.
- Tests do not call GitHub or require a state backend.
- Tests cover the role catalog interface and module defaults, not provider internals.
- Test names explain the intended policy.

## Validation

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
tofu test
```

## Out Of Scope

- Testing actual GitHub API behavior in every pull request.
