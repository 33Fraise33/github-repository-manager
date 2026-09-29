# Task 04: Implement The Repository Module

## Objective

Implement a reusable OpenTofu module that creates and maintains one new GitHub role repository from a catalog entry.

## Prerequisites

- Tasks 00 through 03 are complete.

## Required Work

1. Create `modules/repository` with typed inputs and useful outputs: repository ID, web URL, HTTPS URL, SSH URL, name, and visibility.
2. Use `github_repository` and first-class GitHub provider resources for supported settings.
3. Manage description, visibility, topics, issues, projects, wiki, discussions, merge settings, branch deletion, and Dependabot security updates where supported by the current provider and plan.
4. Enable only squash merging by default, using PR title and body settings compatible with Conventional Commits.
5. Add `prevent_destroy = true`. Do not use `ignore_changes` to conceal normal drift.
6. Make archive status an explicit catalog field. Never delete a repository as part of normal lifecycle management.
7. Wire the root catalog into module instances using `for_each`.
8. Ensure resource settings are valid for both public and private repositories on the personal account plan.

## Acceptance Criteria

- A plan with a sample catalog has only creates for new repositories.
- A second plan is empty after an approved test apply in a disposable target.
- Module outputs are deterministic and documented.
- Delete, replacement, or visibility-change plans are caught by the safety process in `AGENTS.md`.

## Validation

```sh
tofu fmt -check -recursive
tofu init
tofu validate
tofu test
tofu plan
```

Do not apply against the personal account without explicit approval.

## Out Of Scope

- Repository content generation.
- Branch protections unavailable for the selected GitHub plan.
