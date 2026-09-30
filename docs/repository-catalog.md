# Repository Catalog

`catalog.tf` is the typed, declarative interface for new GitHub repositories.
Its `repositories` map is empty by default, so declaring the
catalog does not create a repository. `main.tf` consumes `local.repositories`
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
| `archived` | Yes | Explicit lifecycle state. Set to `true` to archive; do not remove the catalog entry. |
| `homepage` | No | HTTPS URL only. |
| `features` | No | Only the documented `issues` and `discussions` exceptions. |

Repository names, topic syntax, topic counts, visibility, homepage URLs, known
credential signatures, and duplicate names are validated before a plan can run.
Validation is defense in depth, not a substitute for review: never put secrets,
private keys, or other production configuration in the catalog or managed
repositories.

The catalog manages repository settings only. It never initializes or updates
repository content.

Each catalog entry becomes `module.repository["<stable-key>"]`. Removing an
entry proposes a destroy, which is blocked by the module's literal
`prevent_destroy` lifecycle rule. To retire a repository, retain its stable key
and set `archived = true`. Archive and unarchive changes both require explicit
operator approval. The pinned provider's documentation says unarchiving is
unsupported, but its update implementation sends the `archived` value and the
current GitHub REST API supports `false` to unarchive. Do not rely on recovery
through unarchiving until verified during an approved pilot.

## Fixed Defaults

All catalog repositories use these settings. They are policy, not per-entry
switches:

- Default branch: `main`. The repository resource declares `main`, but an empty
  repository has no branch to change; no content is initialized to establish it.
- Issues enabled; repository projects, wikis, and discussions disabled.
- Delete head branches after pull request merge.
- Merge commits, squash merges, and rebase merges enabled. Squash merges use the
  pull request title and body for the commit.
- Auto-merge enabled for public repositories. GitHub Free does not support
  auto-merge for private repositories, so it is disabled there. It still requires
  all applicable pull request and ruleset requirements to pass.
- Dependabot vulnerability alerts and automated security updates enabled.
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

## Module Outputs

The root `repositories` output is keyed by the stable catalog identifier. Each
entry exposes the GitHub numeric ID, repository web URL, HTTPS clone URL, SSH
clone URL, repository name, and visibility.

The module outputs `id`, `web_url`, `https_url`, `ssh_url`, `name`, and
`visibility` come directly from the corresponding repository resource
attributes; no random or time-dependent values are introduced. IDs and URLs
are known after creation. Renaming a stable catalog key is a state-address
migration, not a rename operation.

## Task 04 Verification And Limitations

Task 04 acceptance checks use a mocked GitHub provider, including the identity
data source, and plan-only runs. Run `tofu test` without GitHub credentials;
it does not contact GitHub or the R2 backend. These focused checks cover the
sample public/private catalog, stable output keys, explicit archival, and the
module's settings. Broader catalog and ruleset coverage belongs to task 06.

Review every saved live plan under `AGENTS.md`: deletion and replacement actions,
name, owner, visibility, and archive attribute changes require scrutiny even
when the action counts show only updates. Catalog removal is never the archival
procedure. The lifecycle rule is protection while the resource declaration
remains in configuration; deleting the module/resource code removes that
protection and must be rejected in review.

Compatibility is based on the pinned provider schema/implementation and GitHub's
documented feature availability, not a live apply. The account's default branch
must be `main` before creating empty repositories: the provider accepts this
attribute on creation but does not establish a branch or send a default-branch
change for a new repository. Configuring account settings and creating branch
content are outside this module's scope.

References:

- [Auto-merge plan availability](https://github.com/github/docs/blob/main/data/reusables/gated-features/auto-merge.md)
- [GitHub repository REST API](https://docs.github.com/en/rest/repos/repos#update-a-repository)
- [Pinned repository provider implementation](https://github.com/integrations/terraform-provider-github/blob/v6.13.0/github/resource_github_repository.go)
