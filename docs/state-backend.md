# Cloudflare R2 State Backend

This project stores authoritative OpenTofu state in a private Cloudflare R2
bucket. `backend.tf` is intentionally partial. It contains no account ID,
bucket name, or credentials.

## Out-Of-Band Setup

1. Create a dedicated private R2 bucket. Do not enable public access or connect
   a public `r2.dev` or custom domain.
2. Create an R2 API token restricted to Object Read and Object Write for only
   that bucket. Keep the token secret and record its owner, purpose, and expiry
   in the operator's approved secret manager.
3. Create an ignored `backend.tfbackend` from
   `backend.tfbackend.example`, replacing its bucket and endpoint placeholders.
   The endpoint uses the Cloudflare account ID, which is account-specific
   configuration and is intentionally not committed.
4. Copy `.env.op.example` to the ignored `.env.op`, then set `OP_VAULT` to the
   1Password vault containing the `R2 Tofu State` item. The template maps that
   item's `access key id` and `secret access key` fields to the AWS-compatible
   environment variables. Do not put plaintext credentials in a `.tf` file,
   backend file, command line, plan, state file, or shell history.

## Credentials

Run OpenTofu through `scripts/tofu`. When neither R2 environment variable is
set, it uses `op run` to resolve `.env.op` references for the OpenTofu
subprocess only:

```sh
export OP_VAULT="replace-with-1password-vault-name"
cp .env.op.example .env.op
scripts/tofu init -backend-config=backend.tfbackend
```

Do not use `op read` with command substitution or export resolved credentials
to the parent shell. 1Password references in `.env.op` are resolved only for
the `tofu` process. Do not add the 1Password item itself, its vault name, or
credential values to this repository.

When both `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are already set,
`scripts/tofu` uses them instead and does not invoke 1Password. If only one is
set, it fails without running OpenTofu. This allows trusted CI to provide both
values through its secret environment:

```yaml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
```

## Initialization

Before remote initialization, obtain explicit operator approval that identifies
the Cloudflare account, R2 bucket, state key, and intended read/write actions.
Initialization writes backend metadata locally and may create or update
persistent backend state, so it is not part of routine uncredentialed
validation.

After approval, initialize with the ignored partial configuration:

```sh
scripts/tofu init -backend-config=backend.tfbackend
scripts/tofu state pull >/dev/null
```

Use `scripts/tofu init -reconfigure -backend-config=backend.tfbackend` only
for an approved backend configuration change. Do not use local state for real
GitHub resource operations.

## Locking Test

Before the first real apply, verify native lockfile behavior using an isolated
test state key and two independently initialized working directories. Start a
state-locking command in one directory, then confirm the second command waits
for or rejects concurrent access. Remove only the isolated test state after
approval. Do not force-unlock the authoritative state unless an interrupted
operation has been investigated and the operator explicitly approves it.

R2 supports the S3 conditional writes required by `use_lockfile = true`, but
this backend remains best-effort compatibility. Treat a failed locking test as
a blocker for real repository management.

## Backups And Recovery

R2 does not provide S3 object versioning. Before every approved state-changing
operation, export the current state to an encrypted location outside the R2
bucket and record its checksum and the source commit. The export itself is
read-only against the backend:

```sh
tofu state pull > /approved/encrypted-backups/github-repository-manager.tfstate
shasum -a 256 /approved/encrypted-backups/github-repository-manager.tfstate
```

Do not store backup state in this repository or an unencrypted local directory.
The backup path above is illustrative and must be replaced with an approved
encrypted location.

Test the recovery procedure only against an isolated test state key and only
with approval covering both the test write and cleanup. A recovery to the
authoritative state is state-changing and requires explicit approval. Verify
the backup checksum, inspect the state content, ensure no other operation holds
the lock, and then run the approved `tofu state push <backup-file>` command.
Follow it with `tofu state pull` and checksum comparison. Never overwrite state
to resolve an uncertain situation; stop and investigate first.

## CI Credentials

A future trusted CI apply workflow will receive the R2 access key and secret
only from protected repository secrets. GitHub Actions OIDC does not directly
issue R2 S3 API credentials, so the token must stay narrowly scoped to this
bucket and be rotated on a defined schedule and immediately after suspected
exposure. Fork pull requests and untrusted workflow contexts must never receive
these credentials.
