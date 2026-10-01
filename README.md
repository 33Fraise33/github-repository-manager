# GitHub Repository Manager

OpenTofu configuration for creating and consistently configuring new GitHub repositories in a personal account.

This directory contains OpenTofu configuration for the state backend and project
bootstrap. Complete the task files in numerical order. Each task is intentionally
self-contained so an agent can implement and validate one change at a time.

## Prerequisites

- OpenTofu 1.12.x
- Network access to the OpenTofu Registry for the initial provider download

Routine local validation does not contact GitHub or the Cloudflare R2 backend
and does not require GitHub or R2 credentials:

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
```

## GitHub Authentication

Authenticated GitHub operations target the personal account `33Fraise33`. Read
the [authentication guide](docs/authentication.md) before supplying a token.
Remote authenticated checks additionally require the approved R2 credentials
and operator approval.

## State Backend

Cloudflare R2 is the selected remote state backend. Read the [backend ADR](docs/adr/0001-opentofu-state-backend.md) and [R2 backend operating guide](docs/state-backend.md) before initializing it. Routine local validation must use `tofu init -backend=false`; remote initialization and all state-changing operations require explicit operator approval.

Use `scripts/tofu` only for approved credentialed R2 operations. It loads R2
credentials for its OpenTofu subprocess and is not required for routine local
validation.

## Continuous Integration

Pull requests and pushes to `main` run formatting, backend-disabled
initialization, validation, and the mocked OpenTofu test suite. This job has no
GitHub PAT or R2 credentials. See [the CI guide](docs/ci.md) for the optional,
protected-environment trusted speculative plan setup.

## Scope

- Create and manage newly created repositories with normalized lowercase,
  hyphenated names.
- Support public and private repositories.
- Apply consistent repository settings, topics, merge policy, and security features where GitHub supports them.
- Provide a generic pilot rollout path.

## Repository Catalog

New repositories are declared through the typed [`repositories` catalog](docs/repository-catalog.md). The catalog is empty by default; its example file contains placeholders only and does not create repositories.

Public repositories may optionally declare zero or more
[nonsecret GitHub environments](docs/environments.md), including supported
protection settings, deployment branch/tag rules, and Actions variables. Private
environments are rejected under the personal GitHub Free contract. Secret
references are typed metadata but remain explicitly blocked pending Task 07b;
no secret retrieval or writes are enabled.

## Non-goals

- Importing or changing existing repositories.
- Managing a GitHub organization, teams, organization secrets, or organization rulesets.
- Storing application, infrastructure, or deployment secrets in OpenTofu.
- Automatically applying OpenTofu changes.

## Task Order

1. `tasks/00-select-state-backend.md`
2. `tasks/01-bootstrap-opentofu-project.md`
3. `tasks/02-configure-github-authentication.md`
4. `tasks/03-design-repository-catalog.md`
5. `tasks/04-implement-repository-module.md`
6. `tasks/05-implement-repository-rulesets.md`
7. `tasks/06-add-opentofu-tests.md`
8. `tasks/07-add-ci-plan-workflow.md`
9. `tasks/07a-add-github-environments.md`
10. `tasks/07b-add-ephemeral-1password-secret-retrieval.md`
11. `tasks/08-add-controlled-apply-workflow.md`
12. `tasks/09-create-pilot-repositories.md`
13. `tasks/10-document-operations.md`

Read `AGENTS.md` before executing any task.
