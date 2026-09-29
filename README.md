# GitHub Repository Manager

OpenTofu configuration for creating and consistently configuring new Ansible role repositories in a personal GitHub account.

This directory is a project starter, not OpenTofu configuration yet. Complete the task files in numerical order. Each task is intentionally self-contained so an agent can implement and validate one change at a time.

## Scope

- Create and manage newly created `ansible-role-*` repositories.
- Support public and private repositories.
- Apply consistent repository settings, topics, merge policy, and security features where GitHub supports them.
- Provide a separately managed role template and a pilot rollout path.

## Non-goals

- Importing or changing existing repositories.
- Managing a GitHub organization, teams, organization secrets, or organization rulesets.
- Storing application, infrastructure, or deployment secrets in OpenTofu.
- Automatically applying OpenTofu changes.

## Task Order

1. `tasks/00-select-state-backend.md`
2. `tasks/01-bootstrap-opentofu-project.md`
3. `tasks/02-configure-github-authentication.md`
4. `tasks/03-design-repository-catalog.md`
5. `tasks/04-implement-repository-module.md`
6. `tasks/05-add-role-template-support.md`
7. `tasks/06-add-opentofu-tests.md`
8. `tasks/07-add-ci-plan-workflow.md`
9. `tasks/08-add-controlled-apply-workflow.md`
10. `tasks/09-create-pilot-role-repositories.md`
11. `tasks/10-document-operations.md`

Read `AGENTS.md` before executing any task.
