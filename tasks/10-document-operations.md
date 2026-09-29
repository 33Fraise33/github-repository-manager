# Task 10: Document Operations

## Objective

Document safe day-two operation of the repository manager so future agents and
operators can create, modify, archive, and recover repositories consistently.

## Prerequisites

- Tasks 00 through 09 are complete.

## Required Work

1. Document the standard lifecycle: add a catalog entry, validate, review a plan, obtain explicit approval, apply, verify repository settings, and run a follow-up plan.
2. Document public and private visibility selection, including the current GitHub Free limitation that private repository rulesets are not managed.
3. Document the future decision point for GitHub Pro or an organization plan before enabling private repository rulesets.
4. Document PAT rotation, revocation, expiry handling, and CI secret replacement.
5. Document backend recovery, state locks, interrupted applies, and safe use of `tofu state` commands. Require backups and explicit approval for state surgery.
6. Document repository archival and why deletion, transfer, renaming, and visibility changes require a dedicated change and confirmation.
7. Document a future, separately approved process for importing existing repositories; do not implement imports.
8. Add troubleshooting for GitHub API permissions, provider behavior, rulesets, CI authentication, and drift.

## Acceptance Criteria

- A new operator can safely add one repository without relying on unstated knowledge.
- Recovery procedures do not require credentials to be committed.
- Documentation clearly separates current personal-account limitations from a future organization migration.
- All commands distinguish read-only operations from state-changing operations.

## Validation

- Review every documented command for safety and accuracy.
- Confirm README links to operations documentation and all ADRs.
- Run the standard read-only validation suite.

## Out Of Scope

- Repository content and application deployment.
- Performing a mass migration.
