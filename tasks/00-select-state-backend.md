# Task 00: Select And Configure The State Backend

## Objective

Select a secure remote OpenTofu state backend before any GitHub resource is created, then document and configure the selected backend.

## Prerequisites

- Read `../AGENTS.md` and `../README.md`.
- Local execution is required initially. Preserve compatibility with a future manually dispatched, operator-approved CI apply workflow.

## Required Work

1. Compare Amazon S3, Cloudflare R2, and local state. Record HCP Terraform as rejected because this project must not depend on it.
2. Treat Amazon S3 as the preferred candidate because OpenTofu officially supports it, native S3 lockfiles and bucket versioning provide locking and recovery, and it supports future GitHub Actions OIDC authentication.
3. Treat Cloudflare R2 as a cost-focused candidate because it has a permanent free allowance and supports conditional writes, but document that OpenTofu support is best-effort and R2 lacks S3 object versioning for recovery.
4. Evaluate cost, encryption, locking, recovery, operator access, CI authentication, and bootstrap complexity.
5. Choose a remote backend. Local state is acceptable only for initial configuration validation and must not be used for real GitHub resource creation.
6. Add an ADR at `docs/adr/0001-opentofu-state-backend.md` recording the decision and rejected alternatives.
7. Configure backend code without credentials in version control. Document all required out-of-band setup.
8. Add `.gitignore` entries for state, backups, and plan files.

## Acceptance Criteria

- State is encrypted at rest and protected from accidental public access.
- Concurrent applies are locked.
- At least one recovery path is documented and tested where the backend allows it.
- `tofu init` works with the selected backend after operator-provided credentials are available.
- No state or credentials are committed.

## Validation

```sh
tofu init
tofu state pull >/dev/null
git status --short
```

Do not run `tofu apply` in this task.

## Out Of Scope

- GitHub provider authentication.
- Creating or importing repositories.
