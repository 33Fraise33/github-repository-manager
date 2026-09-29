# ADR 0001: Use Cloudflare R2 For OpenTofu State

## Status

Accepted.

## Context

This project needs remote state before it manages any GitHub repositories. The
backend must support local operator use now and a future manually dispatched CI
apply workflow. State can contain sensitive repository metadata, so it must not
be committed, publicly accessible, or concurrently writable.

## Decision

Use a private Cloudflare R2 bucket through OpenTofu's S3 backend. The backend
configuration in `backend.tf` enables native S3 lockfiles and fixes the state
key. The account-specific S3 endpoint and bucket are supplied from an ignored
partial backend configuration file at initialization time.

R2 encrypts objects at rest and uses TLS for S3 API access. Use an R2 API token
restricted to Object Read and Object Write on only the state bucket. Provide its
S3-compatible credentials through `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`; never place them in backend configuration, OpenTofu
variables, plans, state, or source control.

R2's conditional `PutObject` support permits OpenTofu's native S3 lockfile
mechanism. This is best-effort compatibility rather than an OpenTofu-supported
R2 backend, so locking must be tested during bootstrap before any managed
GitHub resource is created.

Because R2 has no S3 object versioning API, every approved state-changing
operation requires a current encrypted state export stored outside the R2
bucket. Recovery is a manual, explicitly approved `tofu state push` operation.

## Alternatives Considered

| Option | Cost | Encryption and access | Locking and recovery | CI authentication | Decision |
| --- | --- | --- | --- | --- | --- |
| Cloudflare R2 | Includes a permanent free allowance suitable for this small state workload | AES-256 encryption at rest; scoped R2 API tokens | Native lockfiles through conditional writes; no object versioning, so external backups are required | S3-compatible static credentials stored as a CI secret | Selected |
| Amazon S3 | Usage-based storage and request charges | SSE and IAM policies; mature access controls | Official OpenTofu support, native lockfiles, and bucket versioning for recovery | GitHub Actions OIDC can issue short-lived AWS credentials | Preferred technical candidate, not selected because R2's cost model is preferred |
| Local state | No service cost | Depends on each operator's device controls | No shared lock or remote recovery path | Not suitable for CI | Allowed only for `-backend=false` validation |
| HCP Terraform | Service cost and external service dependency | Managed by HCP Terraform | Managed remote state and locking | Service-managed integration | Rejected because this project must not depend on HCP Terraform |

## Consequences

- The bucket must be created and kept private out of band; this project does
  not bootstrap the backend that stores its own state.
- Operators must protect and rotate R2 API credentials. Future CI cannot use
  GitHub Actions OIDC directly for R2's S3 API and will use scoped static
  credentials from a protected repository secret.
- State backup and recovery are operational obligations. The lack of R2 object
  versioning is an accepted tradeoff for the cost model.
- Changing the backend configuration later requires `tofu init -reconfigure`
  and a reviewed migration plan.

## References

- [OpenTofu S3 backend](https://opentofu.org/docs/language/settings/backends/s3/)
- [Cloudflare R2 S3 API compatibility](https://developers.cloudflare.com/r2/api/s3/api/)
- [Cloudflare R2 data security](https://developers.cloudflare.com/r2/reference/data-security/)
- [Cloudflare R2 pricing](https://developers.cloudflare.com/r2/platform/pricing/)
