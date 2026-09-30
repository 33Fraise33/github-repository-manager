# GitHub Authentication

This project manages repositories only in the personal GitHub account
`33Fraise33`. GitHub repository creation for this account uses a fine-grained
personal access token (PAT), supplied only as `GITHUB_TOKEN`. A GitHub App
installation token is not the bootstrap identity for creating repositories in
this personal namespace.

## Token Configuration

Create a fine-grained PAT at GitHub Settings, Developer settings, Personal
access tokens, Fine-grained tokens with these settings:

- Resource owner: `33Fraise33`.
- Repository access: All repositories.
- Repository permissions: Administration read/write and Contents read/write.
- No account or organization permissions.

GitHub includes Metadata read-only automatically. Administration read/write is
required for repository creation, settings, topics, Dependabot security
updates, and repository rulesets. Contents read/write is required to reliably
read and manage the merge settings used by the repository module.

Use the shortest practical expiration and record the expiry in the approved
secret manager. Review these permissions when Tasks 04 and 05 finalize the
repository and ruleset resources.

## Repository Access Limitation

Fine-grained PATs can be restricted to selected existing repositories, but a
token that creates future repositories cannot select repositories that do not
yet exist. The bootstrap token therefore needs All repositories access for
`33Fraise33`. It must not be used for another owner. When repository creation
is no longer needed, replace it with a selected-repositories maintenance token
if GitHub's repository access model permits it.

Administration access also permits destructive API operations. This project
mitigates that authority with `prevent_destroy`, reviewed plans, and the
controlled apply process; token permissions do not replace those safeguards.

## Local Use

Store the PAT in the approved 1Password vault as an item named `GitHub
Repository Manager PAT` with a field named `token`. Copy
`.env.github.op.example` to the ignored `.env.github.op`, set `OP_VAULT`, and
use `scripts/tofu-github` for GitHub-authenticated OpenTofu commands:

```sh
export OP_VAULT="replace-with-1password-vault-name"
cp .env.github.op.example .env.github.op
scripts/tofu-github init -backend=false
tofu validate
```

The wrapper resolves the 1Password reference only for the OpenTofu subprocess.
It rejects a missing token with a non-sensitive message and clears GitHub App
and owner environment variables to prevent an unintended authentication method
or owner override. Do not use `op read` with command substitution, place a PAT
in an OpenTofu variable, pass it on a command line, or enable `TF_LOG` during
normal credentialed operations.

The backend-disabled commands validate configuration but cannot execute the
identity data source because this project has a remote backend. A
`plan -refresh-only` identity check requires the separate operator approval
described in [the state backend guide](state-backend.md). After approved remote
initialization, use the GitHub and R2 wrappers together:

```sh
op run --env-file=.env.github.op -- scripts/tofu plan -refresh-only
```

This plan reads the authenticated GitHub user and creates or modifies no GitHub
resources. Do not run it against the remote backend without the required
approval.

## Rotation And Recovery

1. Before expiry, create a replacement PAT with the same reviewed permissions.
2. Update the 1Password item and the `REPOSITORY_ADMIN_TOKEN` repository secret.
3. Run the approved refresh-only identity check and confirm it authenticates as
   `33Fraise33`.
4. Revoke the replaced PAT in GitHub after the replacement is verified.

If the PAT is exposed, revoke it immediately, inspect GitHub audit and workflow
activity, create and validate a replacement, and review pending plans before
any further apply. Do not attempt to recover by weakening lifecycle protection
or by using a broader classic PAT.

## CI Contract

Tasks 07 and 08 will store this PAT only as the repository secret
`REPOSITORY_ADMIN_TOKEN`. Trusted authenticated OpenTofu plan or apply steps
will map that secret to `GITHUB_TOKEN` only for the command that needs it.
Credential-free formatting, validation, and mocked tests must not receive the
PAT. Fork pull requests, `pull_request_target`, `workflow_run`, plan summaries,
artifacts, and the automatic Actions `GITHUB_TOKEN` must not be used to expose
or substitute this credential.
