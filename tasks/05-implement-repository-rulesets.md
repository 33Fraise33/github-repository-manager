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

## Out Of Scope

- Private repository rulesets on GitHub Free.
- Organization-level or enterprise-level rulesets.
- Required checks tied to repository content.
