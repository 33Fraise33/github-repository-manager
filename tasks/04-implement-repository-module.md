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

## Implementation Decisions And Verification

Implementation complete; local validation passed on 2026-09-30 with OpenTofu
1.12.6 and GitHub provider 6.13.0: `tofu fmt -check -recursive`,
`tofu init -backend=false` (fresh temporary `TF_DATA_DIR`), `tofu validate`,
`tofu test` (four mocked plan-only runs passed), and `git diff --check`.
Deployment has not been performed.

- The module and root catalog wiring are implemented with the pinned GitHub
  provider, explicit archive status, and literal `prevent_destroy` protection.
- GitHub Free supports auto-merge only for public repositories. The root enables
  it for public entries and disables it for private entries; this is the
  account-plan exception to task 03's global auto-merge default.
- Module instances depend on the authenticated-user check so it completes
  before any repository resources can be changed.
- Focused task 04 tests use only mocked GitHub providers and `command = plan`.
  The sample starts from empty test state and declares six new managed resources
  (one repository and two security-settings resources per stable catalog key).
  Broader validation and ruleset coverage remains assigned to task 06.
- A one-off mocked creation/removal check on OpenTofu 1.12.6 confirmed that
  changing the catalog to `{}` fails planning with `Resource instance cannot be
  destroyed` for both repository instances. Mocked-apply cleanup is blocked by
  the same lifecycle protection, so this intentionally failing probe is not
  part of the routine plan-only suite. Its generated mock-only error-state file
  was removed; lifecycle protection was never disabled.
- The deprecated `github_repository.default_branch` attribute is retained for
  the `main` policy. The provider does not establish a branch on creation;
  account default-branch configuration must already be `main`. Creating or
  inspecting content to establish a branch is outside this task.
- The pinned provider's unarchiving documentation conflicts with its update
  implementation and the current REST API. Both archive directions require
  reviewed operator approval, and live unarchiving remains a pilot verification
  item rather than a promised recovery procedure.
- Local initialization may retain R2 backend metadata even with `-backend=false`.
  Use a fresh temporary `TF_DATA_DIR` for backend-independent validation without
  replacing the existing backend initialization or accessing persistent state.

Compatibility is checked against provider source and GitHub documentation.
Actual API behavior and deployment require the separately approved pilot apply;
no real repository or remote state changes are required to complete this task.

## Out Of Scope

- Repository content.
- Repository rulesets.
- Organization-level policy.
