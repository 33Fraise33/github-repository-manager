# Continuous Integration

`.github/workflows/ci.yml` runs credential-free checks on pull requests
targeting `main` and pushes to `main`: formatting, backend-disabled
initialization, validation, and mocked OpenTofu tests. Actions are pinned to
immutable commit SHAs and the workflow token is read-only. Fork pull requests
run only this validation job. Concurrency cancels obsolete validation jobs;
trusted plans use a separate non-cancelling group and cannot be cancelled by
validation concurrency.

## Trusted speculative plans (opt-in)

The `trusted-plan` job is disabled unless the repository variable
`ENABLE_TRUSTED_TOFU_PLAN` is set to `true`. Do not enable it until all setup
below has been reviewed and the protected environment is configured. Once
enabled, eligible events are pushes to `main` and non-Dependabot pull requests
whose head repository is this repository. Fork pull requests cannot satisfy the
job condition.

The job requires approval through the protected GitHub environment
`repository-plan`. Configure required reviewers, prevent self-review where
available, and restrict deployment branches to `main` and same-repository pull
request source branches as appropriate. Reviewers must inspect the exact planned
commit (the PR head commit, not the synthetic merge commit), including workflow
files, OpenTofu configuration, modules, tests, and scripts, before approving:
those files execute while credentials are available.
Environment approval is the credential-release boundary; branch conditions by
themselves are not a trust boundary for executable PR code.

Configure these environment variables and secrets only after explicit operator
approval for the remote read/lock operations:

| Name | Type | Purpose |
| --- | --- | --- |
| `R2_BUCKET` | Variable | Private state bucket name |
| `R2_ENDPOINT` | Variable | HTTPS Cloudflare R2 S3 endpoint |
| `R2_ACCESS_KEY_ID` | Secret | Bucket-scoped R2 Object Read/Write credential |
| `R2_SECRET_ACCESS_KEY` | Secret | Bucket-scoped R2 secret credential |
| `REPOSITORY_ADMIN_TOKEN` | Secret | Approved fine-grained PAT for account `33Fraise33` |

Use a private bucket and the exact state key declared in `backend.tf`. The job
constructs an ephemeral HCL backend config in the runner temp directory and
uses the existing R2 backend; it does not migrate state. The GitHub identity
check uses a separate temporary, backend-free OpenTofu root; the remote backend
is initialized once and the plan reuses the same `TF_DATA_DIR`. Verify the
bucket, endpoint, state key,
workspace, and expected state contents out of band before enabling the variable.
Initialization, refresh, planning, and lockfile operations contact persistent
remote state and therefore require explicit operator approval. R2 credentials
must be scoped to this bucket. The PAT permission and rotation requirements are
documented in [authentication](authentication.md).

Before approving a run, verify its exact commit SHA. Plans run with remote state
locking and a five-minute lock timeout. They do not apply changes and do not
publish a binary plan, JSON plan, raw plan output, or state. The job summary
contains action counts and flags deletion/replacement and changes to repository
name, visibility, or archive state. Deletions and replacements fail the job;
the other flagged changes require operator review. Summary generation failures
fail closed.

Authentication is checked against the configured account before remote backend
initialization. Credential failures report a generic actionable message; token
values and raw plan details are not emitted in the job summary. The automatic
Actions token is read-only and is not used as the GitHub provider credential.

Disable trusted plans by setting `ENABLE_TRUSTED_TOFU_PLAN` to anything other
than `true`. Credential rotation and incident response follow the local
authentication and backend operating guides.

## Verification scope

Local checks verify workflow formatting only insofar as the repository's
OpenTofu formatter applies to `.tf` files; use `actionlint` for workflow syntax
when available. Live same-repository and fork-equivalent event behavior must be
verified in GitHub Actions. Do not enable credentialed plans merely to test
workflow syntax.
