# Task 05: Add Role Template Support

## Objective

Define and implement the relationship between OpenTofu-created repositories and an Ansible role template without duplicating repository settings in shell scripts.

## Prerequisites

- Task 04 is complete.

## Required Work

1. Define a separate `ansible-role-template` repository in the catalog and manage it with the same module.
2. Document the template contract: Galaxy role layout, `meta/argument_specs.yml`, Docker-based Molecule scenario, lint configuration, CI workflow, README, license policy, and `AGENTS.md`.
3. Decide how a new repository receives role-specific content after OpenTofu creation. Evaluate GitHub template creation, Copier, and a bootstrap workflow.
4. Record the decision in an ADR. Do not assume GitHub templates substitute variables or synchronize later template updates.
5. If automation is implemented, make it explicit and idempotent. It must not overwrite non-template role code or secrets.
6. Ensure public roles receive no production inventory, Vault data, or deployment secrets.

## Acceptance Criteria

- OpenTofu owns repository settings; the template owns initial repository content.
- The process for creating a role has documented operator inputs and outputs.
- A role can be initialized from the template without copying secrets.
- Later template updates have a documented propagation process.

## Validation

- Validate OpenTofu normally.
- Test content initialization only in a disposable repository after explicit approval.
- Verify a generated repository contains no secret material.

## Out Of Scope

- Migrating current Ansible roles.
