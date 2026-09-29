# Task 08: Add Controlled Apply Workflow

## Objective

Provide an explicitly operator-approved CI path for applying reviewed OpenTofu changes after the remote state backend and plan workflow are proven.

## Prerequisites

- Tasks 00 through 07 are complete.
- The operator explicitly approves enabling CI applies.

## Required Work

1. Add a manually dispatched workflow limited to the default branch.
2. Require an explicit typed confirmation input containing the intended workspace/environment and commit SHA.
3. Generate a plan and apply that exact saved plan in the same protected run. Do not apply a newly generated unreviewed plan.
4. Add concurrency and backend locking so only one apply can run.
5. Fail closed if the plan includes deletion, replacement, rename, archive/unarchive, transfer, or visibility changes. Require a separate operator-approved override mechanism if such changes are ever needed.
6. Store the PAT only as a repository secret. Do not expose it to untrusted workflow events.
7. Document interrupted-run recovery and state-lock handling.

## Acceptance Criteria

- No push or pull request can apply changes.
- A human must initiate and confirm every apply.
- The applied plan is inspectable and corresponds to the selected commit.
- Destructive changes are blocked before apply.

## Validation

- Validate workflow syntax and permissions.
- Exercise the workflow in plan-only/dry-run form before giving approval for a real apply.
- Do not create a repository during validation without explicit approval.

## Out Of Scope

- Automated repository provisioning on merge.
