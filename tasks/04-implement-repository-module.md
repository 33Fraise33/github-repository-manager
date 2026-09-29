# Task 04: Implement The Repository Module

## Objective

Implement a reusable OpenTofu module that creates and maintains one new GitHub
repository from a catalog entry.

## Prerequisites

- Tasks 00 through 03 are complete.

## Required Work

1. Create `modules/repository` with typed inputs and useful outputs: repository ID, web URL, HTTPS URL, SSH URL, name, and visibility.
2. Use `github_repository` and first-class GitHub provider resources for supported settings.
3. Manage description, visibility, topics, issues, projects, wiki, discussions, merge settings, auto-merge, head-branch deletion, archive status, and Dependabot security updates where supported by the current provider and account plan.
4. Add `archived` as an explicit catalog field. Archival is the normal lifecycle action; deletion is never a catalog operation.
5. Add `lifecycle { prevent_destroy = true }` to every `github_repository` resource. Do not use `ignore_changes` to conceal normal drift.
6. Wire root catalog entries into module instances with `for_each` and retain stable map keys as module addresses.
7. Ensure module settings work for public and private repositories on the current personal GitHub plan, excluding rulesets handled in task 05.
8. Do not create, initialize, alter, or inspect repository content.

## Acceptance Criteria

- A plan with a sample catalog has only creates for new repositories.
- Module outputs are deterministic and documented.
- Archive status is explicit and a catalog removal cannot destroy a repository.
- Delete, replacement, rename, archive/unarchive, transfer, and visibility-change plans are caught by the safety process in `AGENTS.md`.

## Validation

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
tofu test
```

Do not apply against the personal account without explicit approval.

## Out Of Scope

- Repository content.
- Repository rulesets.
- Organization-level policy.
