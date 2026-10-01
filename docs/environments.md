# Optional nonsecret GitHub environments

Task 07a adds opt-in environments to each repository's catalog entry. The
account contract is **personal GitHub Free**, OpenTofu **1.12.x**, and
`integrations/github` **6.13.0**. No real repository opts in in this change.
No environment discovery, import, retrieval, or apply is performed.

## Capability contract

Checked against GitHub documentation and pinned provider source on 2026-10-01.
Live behavior has **not** been verified. A plan/account upgrade requires a
separately reviewed compatibility decision, not removal of these validations.

| Capability | Public / personal Free | Private / personal Free | Module contract |
| --- | --- | --- | --- |
| Environment names | Supported; case-insensitive, maximum 255 characters | Unavailable | Stable logical map key, separate trimmed control-free name; case-insensitive uniqueness within repository |
| Required reviewers | Up to six users; any **one** approves; users need read access | Unavailable | Positive integral user IDs, maximum six; access must be checked separately before apply |
| Team reviewers | Organization-only | Organization-only | Nonempty `reviewer_teams` rejected |
| Prevent self-review | Supported with required reviewers | Unavailable | `prevent_self_review`, default false; requires reviewers |
| Wait timer | 1–43200 minutes; 0 means no wait on creation | Unavailable | Integral `wait_timer`, default 0; decreasing or clearing blocked in review |
| Administrator bypass | Supported | Unavailable | `can_admins_bypass`, defaults **false**, explicitly wired (provider defaults true) |
| Deployment branch/tag policy | All, protected, or selected patterns | Unavailable | `deployment_mode`: `all` (default), `protected`, `custom`; custom requires one or more rules |
| Branch/tag patterns | Individual type-specific rules | Unavailable | Stable rule keys; `type` branch/tag and nonblank pattern, maximum 255 characters; no duplicate type/pattern pair |
| Custom GitHub App protection rules | API supports preview feature | Unavailable | No resource/field in pinned environment provider resource; nonempty `custom_protection_rules` rejected |
| Actions environment variables | Supported | Unavailable | Nonsecret map; canonical uppercase names, no `GITHUB_` prefix/digit start, maximum 100 per environment, 48 KiB per value (UTF-8 bytes) |
| Actions environment secrets | API supports | Unavailable | **Blocked by Task 07b**, even for public repos: provider has sensitive persisted inputs, no write-only input |

Any nonempty environment map on a private repository fails. Only the documented
typed fields are supported; do not invent additional fields (OpenTofu object
conversion can discard undeclared attributes). Supported protection settings are
not silently omitted. Custom rules and team requests use explicit rejection
fields so they cannot accidentally be interpreted as user reviewers.

`protected` refers to **classic branch protection rules**, not this module's
repository ruleset. GitHub documents that if there are no classic branch
protection rules, **all branches can deploy**. For main-only deployment, use
`deployment_mode = "custom"` with an explicit rule `{ type = "branch", pattern = "main" }`
and no other branch/tag rules; do not use `protected` to rely on this repository's
ruleset. Patterns follow GitHub's Ruby
`File.fnmatch` semantics; `*` does not match `/`. No regex/glob containment is
assumed by the plan reviewer.

Sources:

- [GitHub deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)
- [Environment management](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
- [Configuration variable names and limits](https://docs.github.com/en/actions/reference/variables-reference)
- [Environment REST API](https://docs.github.com/en/rest/deployments/environments)
- [Provider environment schema and implementation, v6.13.0](https://github.com/integrations/terraform-provider-github/blob/v6.13.0/github/resource_github_repository_environment.go)
- [Provider deployment policy implementation, v6.13.0](https://github.com/integrations/terraform-provider-github/blob/v6.13.0/github/resource_github_repository_environment_deployment_policy.go)
- [Provider variable implementation, v6.13.0](https://github.com/integrations/terraform-provider-github/blob/v6.13.0/github/resource_github_actions_environment_variable.go)
- [Provider secret inputs, v6.13.0](https://github.com/integrations/terraform-provider-github/blob/v6.13.0/github/resource_github_actions_environment_secret.go)

## Catalog shape (placeholder only)

Add this **inside a public repository entry**, only after separate review:

```hcl
environments = {
  production = {
    name                = "Production"
    reviewers           = [123456] # Placeholder numeric user ID; verify access.
    prevent_self_review = true
    wait_timer          = 30
    can_admins_bypass    = false
    deployment_mode     = "custom"
    deployment_rules = {
      main-branch = { type = "branch", pattern = "main" }
      release-tag = { type = "tag", pattern = "v*" }
    }
    variables = { REGION = "example-region" } # Nonsecret only.
  }
  staging = { name = "Staging" }
}
```

The production example allows deployment from `main` **and** matching release
tags via the `v*` tag rule. For main-only deployment, omit `release-tag` and retain
only `main-branch` with `deployment_mode = "custom"`.

Omitted or `{}` environments create no resources and leave existing unmanaged
environments alone. Stable addresses use repository/environment keys, e.g.
`module.repository["example"].github_repository_environment.this["production"]`.
Rules use `production/main-branch`; variables use `production/REGION`. Variable
names are their stable keys; renaming is replacement, not an in-place value edit.
Repository/environment/rule key changes require reviewed state-address migration.

The `secret_refs` type is metadata only:
`{ DEPLOY_CREDENTIAL = { vault = "<vault>", item = "<item>", field = "<field>" } }`.
**Every nonempty reference map fails** with the Task 07b compatibility blocker.
There is no 1Password provider, secret resource, external helper, plaintext or
ciphertext workaround, or new credential path. References must never contain
secret values. Variables are persisted, nonsecret configuration, not a delivery
path for credentials. Signature rejection catches common mistakes, not every
possible secret; human review must enforce this boundary. No environment values
or references are exported by module/root outputs.

## Lifecycle and review

All three resource types have literal `prevent_destroy = true`. Removing a
previously managed environment, variable, or rule is **not** opting out: it is a
blocked destruction proposal. Never remove lifecycle protection to make it pass.
Removing the entire resource/module configuration also removes its lifecycle
declaration, so the independent plan review and operator approval remain vital.

The sanitized plan helper rejects delete/replace/forget actions, identity changes,
reviewer changes (adding an alternative approver broadens access too), shorter
waits, disabling self-review protection, enabling bypass, deployment mode or
pattern changes, and rule additions to existing environments. Rule creation is
allowed alongside creation of its new environment. Unknown/incomplete protection
evidence fails closed. Conservative rejection includes potentially safe pattern
changes; no attempt is made to prove pattern containment. Variable **value**
updates are allowed but values are never printed. Summaries use resource numbers,
not user-controlled addresses, names, patterns, variable values, or references.

CI invokes `scripts/summarize-tofu-plan.py` when summarizing its trusted
speculative plan. Direct local `tofu apply` and `scripts/tofu apply` do **not**
invoke the helper. Its checks apply only when invoked on plan JSON: they do not
confer operator approval or enforce live deployment policy. Every saved plan
must still be reviewed and explicitly approved before apply; a regenerated or
changed plan requires renewed approval.

Provider limitation: `createUpdateEnvironmentData` uses `GetOk("wait_timer")`,
which omits zero, so a positive-to-zero update cannot reliably clear a timer.
Omitting reviewers produces a nil list; the read path does not clear previously
recorded reviewers when the remote required-reviewers rule is absent. Omitting a
deployment policy similarly does not prove remote policy removal. These
transitions stay blocked; **operator approval alone is not a provider fix**.
Resolve ambiguous clearing through a separately reviewed compatibility/recovery
decision before any apply. No ignore_changes or weakened protections are used.

Before proposing an apply, perform an approved read-only collision/access check
against the expected account and state: stop if any proposed environment already
exists but is not managed in the expected state. GitHub create/update is an
upsert, so a saved plan alone cannot prove absence. Do not import automatically.
This change does not adopt the manager's `repository-plan` CI environment. All
live changes require approval naming account, backend/workspace, repositories,
actions, and the exact reviewed saved plan. A passing summary is not approval.

## Credential-free verification

Inspect mocks and use a fresh temporary `TF_DATA_DIR`; no GitHub/R2/1Password
credentials are needed. Run:

```sh
tofu fmt -check -recursive
tofu init -backend=false -lockfile=readonly
tofu validate
tofu test
python3 -B -m unittest discover -s tests -p 'test_*.py'
git diff --check
```

The OpenTofu suite is mocked and plan-only. Python fixtures exercise protection
review, destruction, unknown evidence and canary redaction without live APIs,
state mutations, or persistent plan artifacts. Mocks prove wiring, not GitHub
API entitlement, reviewer access, or effective live policy enforcement.
