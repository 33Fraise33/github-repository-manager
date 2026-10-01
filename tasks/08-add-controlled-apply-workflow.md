# Task 08: Add Controlled Apply Workflow

## Objective

Provide an explicitly operator-approved CI path for applying reviewed OpenTofu
repository-infrastructure changes after the remote state backend and plan
workflow are proven.

## Prerequisites

- Tasks 00 through 07 are complete.
- Task 07a is complete and Task 07b's compatibility gate has been evaluated.
  Secret-bearing applies require Task 07b complete with a proven safe path;
  a documented blocked outcome permits only nonsecret environment work.
- Task order is **07 → 07a → 07b → 08**; no secret-gate bypass is permitted.
- The operator explicitly approves enabling CI applies.

## Required Work

1. Add a manually dispatched workflow limited to the default branch.
2. Require an explicit typed confirmation input containing the intended workspace or environment and commit SHA.
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
- Exercise the workflow in plan-only form before giving approval for a real apply.
- Do not create a repository during validation without explicit approval.

## Pending Extension: Environment And Secret Apply Safety

Extend plan review to environment/variable/secret-reference removal, rename,
replacement and protection weakening (reviewers, self-review, waits, bypass and
deployment branch/tag access). Require explicit approval for such changes.
Only after Task 07b proves compatibility may the protected run release the
external service-account token to its authorized OpenTofu step. Preserve the
exact reviewed saved-plan contract: ephemeral values are not saved and any
apply-time re-retrieval, rotation/version binding and source changes must follow
Task 07b's documented approval semantics. Fail closed on unsupported paths,
changed intent or unsafe artifacts; never regenerate and apply an unreviewed
plan. This extension is pending and authorizes no CI enablement or real apply.

## Out Of Scope

- Automated infrastructure provisioning on merge.
- Repository content deployment.
