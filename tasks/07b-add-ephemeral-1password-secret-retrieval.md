# Task 07b: Add Ephemeral 1Password Secret Retrieval

## Status And Prerequisites

Pending, compatibility-gated extension; no safe secret path is yet claimed.
Task order is **07 → 07a → 07b → 08**. Task 07a's nonsecret environment support
and secret-reference contract must be complete before implementation.

## Objective

Retrieve referenced environment secrets from 1Password with a dedicated service
account and deliver them through an end-to-end ephemeral OpenTofu path to an
exact, verified write-only GitHub environment-secret destination. Secret values
must never be persisted in OpenTofu state, saved plans, logs, or artifacts.

## Required Work

1. Define a dedicated read-only 1Password service account restricted to the
   intended vault and required items where supported. Document actual access
   granularity and least-privilege limitations; do not silently broaden vault
   access. Supply `OP_SERVICE_ACCOUNT_TOKEN` externally through an approved
   environment/CI secret store, never through catalog values, provider arguments
   containing literals, command lines, committed files, or OpenTofu outputs.
2. Establish an evidence-based compatibility gate before implementing retrieval.
   Record exact OpenTofu, 1Password provider, and GitHub provider versions,
   relevant schemas/source and documentation, the exact ephemeral retrieval
   resource and result attribute, and the exact GitHub environment-secret
   resource/write-only argument and update semantics. The current OpenTofu
   range is 1.12.x and GitHub provider pin is 6.13.0; do not assume either supports
   this path. Review any new provider pin/lockfile or version change separately.
3. Prove every intermediate root/module input and expression preserves ephemeral
   semantics from retrieval through the write-only destination. A `sensitive`
   annotation only redacts display and is not evidence of non-persistence.
   Reject ordinary stateful 1Password data sources, plaintext secret arguments
   stored in state/plans, persisted ciphertext as a workaround, local-exec,
   shell/CLI fallback retrieval or writes, temporary secret files, and outputs.
4. If any source, intermediate, or destination lacks verified support, mark the
   secret feature **blocked**, explain the exact incompatibility and required
   future decision, and fail closed on secret-bearing configuration. Do not
   substitute an unsafe path to satisfy the feature request. Nonsecret Task 07a
   environments may proceed independently; a blocked secret gate cannot be
   bypassed by Task 08.
5. Keep reference metadata declarative (vault/item/field placeholders only in
   examples). Fail closed on missing credentials, inaccessible vaults/items,
   missing fields, invalid references, or destination failures with non-sensitive
   diagnostics. Retrieve only in the approved trusted OpenTofu process, minimize
   lifetime, and prohibit debug logging and credential exposure in summaries,
   caches, artifacts, subprocess arguments, or failure output.
6. Extend trusted CI only after reviewing the exact executing commit, workflow,
   modules, providers, tests, and helpers. Release the service-account token only
   to the authorized OpenTofu step after protected-environment approval. Fork or
   other untrusted code, credential-free validation, `pull_request_target`, and
   `workflow_run` must not receive it. Keep GitHub PAT authentication separate.
7. Define rotation, revocation, expiry, secret update triggers and nonsecret
   version markers where the verified write-only schema requires them. Explain
   saved-plan behavior: ephemeral values must not be serialized and may require
   retrieval again at apply. Identify how reviewed reference/version intent is
   bound to the exact saved plan and how changes in 1Password between plan and
   apply are detected or constrained. Changed intent requires a new plan and
   renewed approval, never an unreviewed replacement apply.

## Acceptance Criteria

- The compatibility report proves an exact end-to-end ephemeral/write-only path,
  or records a clear blocked outcome with no secret implementation fallback.
- Only intended vault access is granted; the external service-account token and
  retrieved values are never committed or persisted by OpenTofu or CI.
- Secret reads/writes fail closed and cannot run for untrusted events. Reference
  changes, rotation and saved-plan approval semantics are explicit and testable.
- No claim of live secret delivery is made without a separately approved apply.

## Validation

Inspect mocks, aliases and helpers first. Routine validation remains credential
free, with GitHub and 1Password mocked and synthetic values only:

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
tofu test
```

Use a fresh temporary `TF_DATA_DIR` for backend-independent checks. Add isolated
synthetic tests for unsupported capabilities, missing/inaccessible references,
failures, rotation and saved-plan behavior. Verify synthetic canary values are
absent from state, binary and JSON plans, logs, error output, summaries, caches,
and artifacts, including failure paths. Record whether test tooling can exercise
ephemeral/write-only semantics; mocks alone do not prove provider behavior.
If coverage or compatibility is insufficient, report the gap and keep the gate
blocked. Any real retrieval or API write requires separate explicit approval;
routine tests must not require a service account or GitHub credentials.

## Out Of Scope

- Provisioning a real service account, retrieving real secrets, or live writes
  during routine validation.
- Broader secret management, stateful fallback, or automatic deployment.
