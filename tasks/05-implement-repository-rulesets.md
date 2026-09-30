# Task 05: Implement Repository Rulesets

## Objective

Apply consistent, repository-level default-branch protections where the target
account plan supports them.

## Prerequisites

- Task 04 is complete.
- The repository module has established a default branch suitable for ruleset targeting.

## Required Work

1. Implement `github_repository_ruleset` as a first-class provider resource, dependent on its managed repository.
2. Apply the active default-branch ruleset only to public repositories while the target personal account uses GitHub Free.
3. Require pull requests and resolved review threads, allow zero required approvals, and prohibit default-branch deletion and force pushes.
4. Permit merge, squash, and rebase methods in the ruleset.
5. Do not configure required status checks, code-owner review, content policies, or bypass actors by default.
6. Use `~DEFAULT_BRANCH` rather than a hard-coded branch name and add lifecycle protection appropriate for the ruleset resource.
7. Document that private repository rulesets require an explicit future decision to upgrade to GitHub Pro or migrate to an organization plan such as GitHub Team. Do not silently skip or weaken an expected private ruleset after that decision.

## Acceptance Criteria

- Public managed repositories receive the fixed active ruleset.
- Private managed repositories receive no ruleset while the account remains on GitHub Free.
- Ruleset policy is not configurable per catalog entry.
- Ruleset removal is protected from accidental infrastructure changes.

## Validation

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
tofu test
```

Test live ruleset behavior only in an explicitly approved disposable public repository.

## Implementation Decisions And Verification

Implementation complete; backend-independent local validation passed on
2026-09-30 with OpenTofu 1.12.6 and GitHub provider 6.13.0:
`tofu fmt -check -recursive`, `tofu init -backend=false` using a fresh
temporary `TF_DATA_DIR`, `tofu validate`, `tofu test` (four mocked plan-only
runs passed), and `git diff --check`. No live plan or apply was performed.

- The repository module creates a fixed active ruleset for public repositories
  only. It targets `~DEFAULT_BRANCH`, requires pull requests and resolved review
  threads, allows zero approvals, and prohibits deletion and force pushes. The
  permitted merge methods are merge, squash, and rebase.
- No bypass actors, required status checks, code-owner review, or content rules
  are configured. Ruleset policy is not a catalog input.
- Rulesets have literal `prevent_destroy`. A public-to-private visibility
  transition would make the ruleset instance no longer desired and is blocked
  from accidental removal.
- Provider v6.13.0 refuses to create a ruleset on an archived repository and
  skips ruleset updates while archived. The public ruleset remains declared
  when archival is set, avoiding a ruleset destroy. Create it before separately
  approving archival; updates while archived are not guaranteed to reach
  GitHub.
- GitHub Free does not provide private-repository rulesets for this personal
  account. Enabling them later requires an explicit decision to upgrade to
  GitHub Pro or move management to an appropriate organization plan, followed
  by a reviewed configuration change.
- The existing test suite emits deprecation warnings for the repository
  provider's `default_branch` attribute. This is pre-existing Task 04 policy and
  outside the scope of Task 05.

Validation was entirely local and used mocked providers. Deployment and live
ruleset behavior have not been verified.

## Out Of Scope

- Private repository rulesets on GitHub Free.
- Organization-level or enterprise-level rulesets.
- Required checks tied to repository content.
