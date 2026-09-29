# Repository Catalog

`catalog.tf` is the typed, declarative interface for new GitHub repositories.
Its `repositories` map is empty by default, so declaring the
catalog does not create a repository. Task 04 will consume `local.repositories`
to create one module instance per entry.

Each map key is a stable lowercase identifier. It becomes the OpenTofu resource
address and must not be renamed after a repository is managed. Add repositories
as small, reviewed entries in the tracked `repositories.auto.tfvars` catalog;
`catalog.tfvars.example` contains public and private placeholder examples only
and is not loaded automatically.

## Catalog Fields

| Field | Required | Policy |
| --- | --- | --- |
| `name` | Yes | Must be a unique normalized lowercase, hyphenated name. |
| `description` | Yes | Repository description; do not include credentials or private operational details. |
| `visibility` | Yes | `public` or `private`. |
| `topics` | Yes | Lowercase, hyphenated GitHub topics. Topics are public even on private repositories. |
| `homepage` | No | HTTPS URL only. |
| `features` | No | Only the documented `issues` and `discussions` exceptions. |

Repository names, topic syntax, topic counts, visibility, homepage URLs, known
credential signatures, and duplicate names are validated before a plan can run.
Validation is defense in depth, not a substitute for review: never put secrets,
private keys, or other production configuration in the catalog or managed
repositories.

The catalog manages repository settings only. It never initializes or updates
repository content.

## Fixed Defaults

All catalog repositories use these settings. They are policy, not per-entry
switches:

- Default branch: `main`.
- Issues enabled; repository projects, wikis, and discussions disabled.
- Delete head branches after pull request merge.
- Merge commits, squash merges, and rebase merges enabled. Squash merges use the
  pull request title and body for the commit.
- Auto-merge enabled. It still requires all applicable pull request and ruleset
  requirements to pass.
- Task 04 requires `prevent_destroy` as a literal lifecycle setting on every
  managed repository resource.
- Public repositories receive an active default-branch ruleset requiring pull
  requests and resolved review threads, allowing zero required approvals, and
  prohibiting branch deletion and force pushes. It allows merge, squash, and
  rebase methods.

`features.issues = false` or `features.discussions = true` requires a concise,
non-empty `features.justification`. No other feature override is supported.
This keeps exceptions visible in review while matching the existing account
baseline for issues, projects, wikis, discussions, and the `main` branch. Branch
cleanup, auto-merge, and default-branch protections are intentional consistent
defaults. Required status checks are not managed because their names are
repository-content-specific.
GitHub Pro is required to enforce this ruleset on private repositories owned by
a personal account. While this account uses GitHub Free, task 05 applies the
ruleset only to public repositories.

## Deliberately Unmanaged Settings

This project manages only the repository settings declared in the catalog and
the repository module introduced in task 04. It does not manage collaborators,
repository invitations, deploy keys, webhooks, GitHub Apps, Actions secrets or
variables, environments, Pages, releases, labels, milestones, or repository
content.

Organization-only controls remain out of scope for this personal account:
organizations, teams, organization roles, organization secrets and variables,
organization rulesets, member policies, billing, and enterprise controls. Branch
protection rules are not used; task 05 will implement the fixed public
repository ruleset policy defined above. Required status checks are deliberately
unmanaged.
