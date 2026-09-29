# Task 03: Design The Repository Catalog

## Objective

Create the typed declarative interface that describes newly managed role repositories and applies safe, consistent defaults.

## Prerequisites

- Tasks 00 through 02 are complete.

## Required Work

1. Define a `repositories` map variable or equivalent catalog file keyed by a stable identifier.
2. Support only the initial attributes needed for role repositories: name, description, visibility, topics, template selection, homepage, and explicitly justified feature overrides.
3. Add safe global defaults: `main` as default branch, issues enabled, wikis disabled, discussions disabled unless explicitly needed, delete head branches on merge, and one approved merge method.
4. Validate that names match `ansible-role-[a-z0-9-]+`, visibility is `public` or `private`, topics are normalized, and catalog entries cannot contain secrets.
5. Add examples for one public role and one private role. Examples must use placeholder names and no real credentials.
6. Document which settings are deliberately not managed on personal repositories, including organization-only controls.

## Acceptance Criteria

- Adding a repository is a small, reviewable catalog change.
- Invalid names and visibility values fail at plan time.
- Defaults can be overridden only through documented fields.
- No GitHub resources are created by this task.

## Validation

```sh
tofu fmt -check -recursive
tofu validate
tofu test
```

## Out Of Scope

- Module resource implementation.
- Existing repository imports.
