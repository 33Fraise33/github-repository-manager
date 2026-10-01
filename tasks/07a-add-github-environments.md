# Task 07a: Add GitHub Environments

## Status And Prerequisites

Nonsecret implementation submitted for review; no deployment is claimed.
Task order is **07 → 07a → 07b → 08**. Tasks 00 through 07 must be complete
before implementation. Secret value retrieval and writes are gated by
[Task 07b](07b-add-ephemeral-1password-secret-retrieval.md).

## Objective

Allow each repository to optionally configure zero, one, or multiple GitHub
environments through the repository module, covering all environment
configuration supported by the GitHub API, personal-account plan, and pinned
provider. Store declarative nonsecret settings and secret references, never
secret values, in the catalog.

## Required Work

1. Extend the root catalog and module with an optional typed `environments` map
   defaulting to `{}`. Use stable logical keys independent of environment names
   for resource addresses. Validate names, uniqueness, limits, and incompatible
   settings; key changes are state-address migrations, not routine renames.
2. Evaluate and record a capability matrix against current GitHub API docs,
   account plan and public/private visibility, and the pinned GitHub provider
   schema/source (currently 6.13.0). Cover environment names, required reviewers,
   prevention of self-review, wait timers, supported deployment protection rules
   including administrator bypass controls, deployment branch/tag policies and
   patterns, environment variables, and environment secrets. Explain unsupported
   or organization-only settings and fail clearly when requested; never silently
   omit them, weaken protection, or imply universal support. Any necessary
   provider/version change requires a separately reviewed compatibility decision.
3. Manage supported environment, protection, branch/tag rule, and variable
   resources inside `modules/repository` with first-class GitHub provider
   resources. Scope every resource to its repository and stable environment key;
   preserve existing repository settings and lifecycle protections.
4. Add a typed map of environment secret names to 1Password references containing
   only vault/item/field identifiers. Examples use placeholders such as
   `<vault>`, `<item>`, and `<field>`, not secret values. Variables are nonsecret;
   credentials must never be disguised as variables. Validate references without
   retrieving them. Task 07b must prove a safe destination and ephemeral path
   before secret writes are enabled; otherwise reject secret-bearing requests
   with an actionable blocker while allowing nonsecret environments to proceed.
5. Omitted or empty environments on repositories with no managed environments
   create no environment resources and leave existing unmanaged environments
   unchanged. Do not discover, import, or take ownership of environments
   implicitly. Removing previously managed entries is a removal proposal, not
   the same as never opting in.
6. Define reviewed lifecycle behavior for environments, variables, secret
   references, and deployment rules. Flag removal, rename, replacement, reviewer
   removal, shorter waits, broader deployment access, and enabling bypass as
   destructive or protection-weakening changes requiring explicit approval.
   Preserve protections; do not remove them merely to allow a plan to succeed.

## Acceptance Criteria

- Existing catalogs remain valid without opting in; zero/multiple environments
  are wired by stable repository/environment keys with no cross-repository scope.
- Supported settings are fully configurable; unsupported requests fail with
  documented account/API/provider reasons rather than silently degrading.
- No secret value appears in catalog, module outputs, fixtures, state, plans,
  logs, or artifacts. Secret writes remain blocked pending Task 07b evidence.
- Environment lifecycle and protection weakening are visible in plan review and
  cannot bypass operator approval. No live changes occur during routine tests.

## Validation

Inspect all provider mocks, aliases, and helpers before running the existing
credential-free suite:

```sh
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
tofu test
```

Use a fresh temporary `TF_DATA_DIR` if local backend metadata is initialized.
Add mocked plan-only coverage for omitted/empty/multiple environments, stable
addresses, names and invalid combinations, public/private capability rejection,
reviewer/self-review/wait/bypass controls, branch/tag policies, variable wiring,
reference validation and the secret gate. Test lifecycle declarations and plan
review detection without a destructive apply or lifecycle-disabled cleanup.
Live API verification requires separate approval; document unverified behavior.

## Out Of Scope

- Secret retrieval or secret writes before Task 07b's compatibility gate passes.
- Repository content, automatic imports, organization policy, or live deployment.

## Implementation Decisions And Verification

- Added optional typed environment maps with stable keys, public/personal-Free
  capability validation, provider resources for environments/rules/variables,
  and literal destruction protection. Existing real catalog remains unchanged.
- [Capability and operating contract](../docs/environments.md) records pinned
  provider source evidence, account limits, unsupported requests, collision
  checks, classic branch protection fallback, and secret gating. Defaults disallow
  administrator bypass. Nonempty secret references fail; Task 07b remains blocked.
- Sanitized plan review blocks destructive actions and conservative protection
  changes, including unknown evidence. Provider 6.13.0 cannot reliably clear
  wait timers via zero and has ambiguous reviewer/policy clearing; those
  transitions must not be applied even with routine operator approval.
- Credential-free mocked plan suite passed with OpenTofu 1.12.6 (41 passed);
  backend-disabled readonly-lock initialization and validation passed in a fresh
  isolated temporary data directory. Existing default_branch deprecation warnings
  remain. Synthetic summary/redaction tests passed (9 tests with subcases) and
  are included in validation CI. Formatting and `git diff --check` passed.
- No live GitHub/R2/1Password operation, state migration/import/apply, real catalog
  opt-in, or adoption of the manager's own CI plan environment was performed.
