# Task 09: Create Pilot Repositories

## Objective

Prove the repository module, public ruleset policy, state tracking, and
controlled apply process with one operator-selected public repository.

## Prerequisites

- Tasks 00 through 08 are complete.
- The operator selects the exact repository name and explicitly approves creation.

## Required Work

1. Add exactly one durable public repository entry to the catalog.
2. Review the saved plan: it must contain one repository create and its non-destructive related settings, including the public default-branch ruleset.
3. Obtain explicit approval, then apply only the reviewed saved plan through the approved path.
4. Verify visibility, description, topics, issues, projects, wiki, discussions, merge policy, auto-merge, branch deletion policy, force-push policy, Dependabot settings, cloning, and absence of drift.
5. Run a follow-up plan and confirm it is empty.
6. Record any GitHub provider or personal-account limitation and add a regression test where appropriate.
7. Defer private repository pilots and private rulesets until the operator decides whether to use GitHub Pro or an organization plan.

## Acceptance Criteria

- Exactly one approved public repository is created.
- The fixed public ruleset is active and effective.
- The follow-up plan has no drift.
- No repository content is created or managed by this project.

## Validation

```sh
tofu plan
tofu test
```

The apply and external GitHub verification require explicit operator approval.

## Out Of Scope

- Private repository pilots until the account-plan decision.
- Importing existing repositories.
