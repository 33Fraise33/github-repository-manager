# Task 10: Document Operations

## Objective

Document the safe day-two operation of the repository manager so future agents and operators can create, modify, archive, and recover repositories consistently.

## Prerequisites

- Tasks 00 through 09 are complete.

## Required Work

1. Document the standard lifecycle: add catalog entry, validate, review plan, explicitly apply, initialize content, verify CI, and pin the role in the deployment repository.
2. Document public/private selection criteria and the rule that secrets and inventory never enter role repositories.
3. Document PAT rotation, revocation, expiry handling, and CI secret replacement.
4. Document backend recovery, state locks, interrupted applies, and safe use of `tofu state` commands. Require backups and explicit approval for state surgery.
5. Document how to archive a repository and why deletion, transfer, renaming, and visibility changes require a dedicated change and confirmation.
6. Document a future, separately approved process for importing existing repositories; do not implement imports.
7. Document how the deployment repository installs pinned public and private role versions through `requirements.yml` and how updates are reviewed.
8. Add a troubleshooting guide for GitHub API permissions, provider behavior, template initialization, CI authentication, and drift.

## Acceptance Criteria

- A new operator can safely add one role repository without relying on unstated knowledge.
- Recovery procedures do not require credentials to be committed.
- Documentation clearly separates current personal-account limitations from a future organization migration.
- All commands distinguish read-only operations from state-changing operations.

## Validation

- Review every documented command for safety and accuracy.
- Confirm README links to operations documentation and all ADRs.
- Run the standard read-only validation suite.

## Out Of Scope

- Performing a mass migration.
