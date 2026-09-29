# Task 09: Create Pilot Role Repositories

## Objective

Prove the repository module and template process with one public and one private Ansible role repository before broader adoption.

## Prerequisites

- Tasks 00 through 08 are complete.
- The operator selects exact repository names and explicitly approves creation.

## Required Work

1. Select two low-coupling roles from the existing Ansible repository. Prefer `photon` as a public pilot; choose a private role with no production secrets in its role code for the second pilot.
2. Add only these two entries to the repository catalog.
3. Review the plan: it must contain exactly two repository creates and related non-destructive settings.
4. Obtain explicit approval, then apply through the approved path.
5. Initialize both repositories from the role template using the process from task 05.
6. Verify visibility, description, topics, issues/wiki/discussions settings, merge policy, Dependabot settings, cloning, role CI, Molecule execution, and absence of secrets.
7. Run a follow-up plan and confirm it is empty.
8. Record any GitHub provider or personal-account limitation in documentation and add a regression test if appropriate.

## Acceptance Criteria

- Exactly two approved repositories are created.
- Public and private visibility are correct.
- Both repositories validate their role content in CI without production secrets.
- The OpenTofu follow-up plan has no drift.

## Validation

```sh
tofu plan
tofu test
```

The apply and external GitHub verification require explicit operator approval.

## Out Of Scope

- Moving all existing roles.
- Importing legacy repositories.
