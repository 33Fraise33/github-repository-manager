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

## Out Of Scope

- Testing actual GitHub API behavior in every pull request.
