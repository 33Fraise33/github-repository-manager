# Task 01: Bootstrap The OpenTofu Project

## Objective

Create a reproducible OpenTofu project skeleton that can be validated locally without contacting GitHub or the selected state backend.

## Prerequisites

- Task 00 has selected and documented the backend.

## Required Work

1. Create a clear layout such as `modules/repository/`, `tests/`, `docs/adr/`, and root OpenTofu files.
2. Add an OpenTofu `required_version` compatibility constraint and required provider version constraints. Pin the GitHub provider from `integrations/github`.
3. Use OpenTofu's compatible `terraform {}` configuration block; retain the standard `.tf` file extension and `.terraform.lock.hcl` lock-file name.
4. Add a root `versions.tf`, provider configuration using variables or environment-based authentication only, and backend configuration consistent with task 00.
5. Add `.gitignore`, `.editorconfig`, and a concise README with prerequisites and safe local commands.
6. Generate and commit `.terraform.lock.hcl`.
7. Add static tooling configuration chosen by the implementation, such as TFLint and Trivy, only if it can be maintained in CI.

## Acceptance Criteria

- A clean clone can initialize providers with `-backend=false`.
- Formatting and validation pass without GitHub credentials.
- The lock file is committed.
- No resources are defined yet, except backend-independent scaffolding needed for validation.

## Validation

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
git diff --check
```

## Out Of Scope

- Adding a PAT.
- Creating a repository.
