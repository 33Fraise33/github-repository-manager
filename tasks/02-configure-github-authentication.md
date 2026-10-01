# Task 02: Configure GitHub Authentication

## Objective

Configure least-privilege authentication for managing repositories in the personal GitHub account without exposing credentials in source control, logs, or OpenTofu state.

## Background

GitHub's personal repository creation endpoint requires a user access token. A GitHub App installation token is not the bootstrap identity for creating repositories in a personal namespace. Use a fine-grained PAT supplied as `GITHUB_TOKEN`.

## Required Work

1. Determine and document the smallest fine-grained PAT permission set required by the implemented repository settings. Start with repository administration read/write only when necessary; do not request unrelated account permissions.
2. Restrict the token to the personal account and only intended repositories where GitHub permits this. Document the limitation that a token creating future repositories may require broader owner access.
3. Document token creation, secure storage, expiry, rotation, revocation, and emergency recovery in `docs/authentication.md`.
4. Configure the provider to consume `GITHUB_TOKEN` from the environment, not an OpenTofu variable.
5. Add a read-only identity or repository data-source check that verifies authentication without creating or changing resources.
6. Ensure CI receives the token only from a repository secret and only in trusted contexts.

## Acceptance Criteria

- No credential value appears in code, state, plans, logs, or committed files.
- The documented token can read the account/repository data needed by the provider.
- A missing token fails with a clear, non-sensitive message.
- The project does not claim GitHub App authentication is used for personal repository creation.

## Validation

```sh
tofu init
tofu validate
tofu plan -refresh-only
```

The operator must provide `GITHUB_TOKEN`; do not request or print it.

## Pending Extension: Tasks 07a And 07b

Revisit the least-privilege GitHub PAT permissions for environment settings,
variables and secrets using API/provider evidence; do not broaden them silently.
Task 07b adds a separate dedicated read-only 1Password service account restricted
to the intended vault, with `OP_SERVICE_ACCOUNT_TOKEN` supplied externally only
to the authorized trusted OpenTofu step. Document its expiry, rotation and
revocation without retrieving secrets. Existing PAT authentication is not proof
of an ephemeral environment-secret path; that path remains compatibility-gated.
This extension is pending and does not change prior authentication work.

## Out Of Scope

- Creating a real repository.
- GitHub organization configuration.
