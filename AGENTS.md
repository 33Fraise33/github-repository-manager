# Repository Guide

## Purpose

This repository manages new GitHub repositories owned by a personal account. Its initial consumers are independently versioned Ansible roles. The source of truth is OpenTofu; do not make corresponding GitHub settings changes manually unless an approved recovery procedure requires it.

## Execution Rules

- Work only on the assigned task. Confirm its prerequisites are complete before implementation. If instructed to process the task queue, work in numeric order.
- Use a feature branch. Do not commit directly to `main`.
- Use Conventional Commit messages.
- Make the smallest correct change. Do not introduce infrastructure outside a task's scope.
- Distinguish implementation complete, validation passed, and deployment complete. Never claim deployment without an approved successful apply. If validation is blocked, report the command, blocker, and remaining verification.
- Update task documentation only when an implementation decision, limitation, or deviation must be recorded.

## Approval And Safety

- Explicit operator approval is required before changing managed GitHub resources or persistent OpenTofu state, regardless of the command, script, API, or workflow used. This includes imports, state mutations, backend migrations, and force-unlocking state.
- Before requesting approval, present the target account, backend or workspace, affected repositories, and proposed actions. Apply only the reviewed saved plan. A regenerated or changed plan requires renewed approval.
- Never create, delete, transfer, rename, archive, unarchive, or change the visibility of a real repository without explicit operator approval.
- Pushing a feature branch and opening a pull request are permitted when they do not change managed GitHub resources or persistent OpenTofu state.
- Inspect plan attribute changes as well as action counts. Treat delete, replacement, rename, transfer, archive, unarchive, and visibility changes as blocked.
- Never commit `*.tfstate`, `*.tfstate.*`, `.terraform/`, saved plan files regardless of filename, plan JSON, provider credentials, PATs, private keys, `.env` files, or CI secrets.
- Do not pass credentials on command lines. Read credentials only from approved environment variables or the selected CI secret store.
- Do not add a production secret to OpenTofu variables, outputs, state, test fixtures, task files, or documentation examples.

## Scope And Identity

- Configure the expected GitHub owner explicitly and verify the authenticated identity before live operations.
- Use a map with stable logical keys for repository resources. Treat key changes as state-address migrations.
- If a proposed repository already exists but is absent from the expected state, stop and report the collision. Do not import it automatically.
- Manage only the repository settings declared in this project. Role implementation, release contents, and unrelated account settings remain outside scope unless explicitly assigned.

## Authentication

- The target is a personal GitHub account. Creating repositories requires a user-scoped credential, such as the approved fine-grained PAT; do not substitute a GitHub App installation token for this operation.
- Use the narrowest viable fine-grained PAT through `GITHUB_TOKEN`. Document the exact permissions and rotation procedure; do not display its value.
- In CI, store the approved PAT as `REPOSITORY_ADMIN_TOKEN` and expose it as `GITHUB_TOKEN` only to the authorized OpenTofu step. Do not substitute the automatic Actions token or broaden permissions silently.
- Authentication checks must be read-only until the operator approves a real apply.

## OpenTofu Standards

- Pin the OpenTofu CLI compatibility range and every provider version. Commit `.terraform.lock.hcl`.
- Use the `integrations/github` provider and provider resources rather than `local-exec`, `null_resource`, curl, or GitHub CLI for managed settings.
- Keep the repository catalog declarative and typed. Validate names, visibility, and unsafe combinations at plan time.
- Default to `prevent_destroy = true` for managed repositories. Prefer archival over deletion.
- Do not make a backend, provider, or lifecycle change that invalidates existing state without an approved migration plan.
- Never remove or weaken lifecycle protection merely to make a plan succeed. Removing a catalog entry is not the archival procedure; archival must be an explicit, reviewed configuration change.

## Verification And Tests

- At minimum run `tofu fmt -check -recursive`, `tofu init -backend=false`, and `tofu validate`.
- Routine tests must use mocked providers and require no GitHub credentials. Inspect test files, provider aliases, and helper modules before execution. Tests that create or modify real resources require explicit approval covering both creation and cleanup. Report skipped tests and the reason.
- Once a test suite exists, run only the exact approved test command defined by the active task.
- CI workflows must pin third-party actions to immutable commit SHAs and use least-privilege `permissions`.
- Credentialed jobs must execute only reviewed, trusted configuration. Never use `pull_request_target` or `workflow_run` to execute untrusted pull-request code with secrets.
- Record the commands run and their results in the pull request or task completion summary.
