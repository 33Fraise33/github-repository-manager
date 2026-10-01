#!/usr/bin/env python3
"""Print a sanitized OpenTofu plan summary and reject destructive actions."""

import json
import sys


ENVIRONMENT = "github_repository_environment"
POLICY = "github_repository_environment_deployment_policy"
VARIABLE = "github_actions_environment_variable"


def contains_unknown(value: object) -> bool:
    if isinstance(value, dict):
        return any(contains_unknown(item) for item in value.values())
    if isinstance(value, list):
        return any(contains_unknown(item) for item in value)
    return value is True


def environment_review(resource: dict, new_environments: set[tuple]) -> list[str]:
    """Conservatively block changes whose protection effect cannot be proven safe."""
    kind = resource.get("type")
    if kind not in (ENVIRONMENT, POLICY, VARIABLE):
        return []
    change = resource["change"]
    actions = change["actions"]
    if actions == ["no-op"]:
        return []
    before, after = change.get("before") or {}, change.get("after") or {}
    unknown = change.get("after_unknown") or {}
    reasons = []
    for attribute in ("repository", "environment"):
        if not after.get(attribute) or contains_unknown(unknown.get(attribute)) or (
            before and before.get(attribute) != after.get(attribute)
        ):
            reasons.append("environment identity change or unknown identity")
    if kind == ENVIRONMENT:
        protected = ("reviewers", "wait_timer", "prevent_self_review", "can_admins_bypass", "deployment_branch_policy")
        if any(contains_unknown(unknown.get(attr)) for attr in protected):
            reasons.append("unknown environment protections")
        if not all(attr in after for attr in protected):
            reasons.append("incomplete environment protection evidence")
    if kind == ENVIRONMENT and "update" in actions:
        if not all(attr in before and attr in after for attr in protected):
            reasons.append("incomplete environment protection evidence")
            return reasons
        if (after.get("wait_timer") or 0) < (before.get("wait_timer") or 0):
            reasons.append("shorter wait; clearing zero is unsupported by provider 6.13.0")
        def reviewers(value: list) -> set[tuple]:
            return {(kind, identifier) for block in value or []
                    for kind in ("users", "teams") for identifier in block.get(kind, []) or []}
        old_reviewers = reviewers(before.get("reviewers"))
        new_reviewers = reviewers(after.get("reviewers"))
        # Adding an eligible approver also broadens access (only one must approve).
        if old_reviewers != new_reviewers:
            reasons.append("reviewer access changed; clearing reviewers is unverified")
        if before.get("prevent_self_review") and not after.get("prevent_self_review"):
            reasons.append("self-review protection disabled")
        if not before.get("can_admins_bypass") and after.get("can_admins_bypass"):
            reasons.append("administrator bypass enabled")
        if before.get("deployment_branch_policy") != after.get("deployment_branch_policy"):
            reasons.append("deployment mode changed; effect or clearing cannot be proven safe")
    if kind == POLICY:
        if "update" in actions or any(contains_unknown(unknown.get(attr)) for attr in ("branch_pattern", "tag_pattern")):
            reasons.append("deployment pattern changed or unknown")
        if "create" in actions and (after.get("repository"), after.get("environment")) not in new_environments:
            reasons.append("deployment rule added to existing or unknown environment")
    if kind == VARIABLE:
        if contains_unknown(unknown.get("variable_name")):
            reasons.append("unknown environment variable identity")
        if before and before.get("variable_name") != after.get("variable_name"):
            reasons.append("environment variable renamed")
    return reasons


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: summarize-tofu-plan.py PLAN_JSON", file=sys.stderr)
        return 2

    with open(sys.argv[1], encoding="utf-8") as plan_file:
        plan = json.load(plan_file)

    # OpenTofu omits resource_changes when there are no resource changes.
    resources = plan.get("resource_changes", [])
    if not isinstance(resources, list):
        raise ValueError("Malformed resource change evidence")
    allowed_actions = {"no-op", "create", "read", "update", "delete", "forget"}
    for resource in resources:
        if not isinstance(resource.get("type"), str) or not resource["type"]:
            raise ValueError("Missing resource type evidence")
        actions = resource.get("change", {}).get("actions")
        if not isinstance(actions, list) or not actions or any(action not in allowed_actions for action in actions):
            raise ValueError("Unknown resource actions")
    new_environments = {
        (resource["change"].get("after", {}).get("repository"), resource["change"].get("after", {}).get("environment"))
        for resource in resources
        if resource.get("type") == ENVIRONMENT and resource["change"]["actions"] == ["create"]
    }

    counts: dict[str, int] = {}
    hazardous: list[str] = []
    sensitive_changes: list[str] = []
    for index, resource in enumerate(resources, 1):
        change = resource.get("change", {})
        actions = change.get("actions", [])
        action = "+".join(actions) if actions else "no-op"
        counts[action] = counts.get(action, 0) + 1
        before = change.get("before") or {}
        after = change.get("after") or {}
        # Do not print addresses: user-controlled keys can themselves carry values.
        address = f"resource #{index}"

        if any(item in actions for item in ("delete", "forget")):
            hazardous.append(f"{address}: {action}")
        for reason in environment_review(resource, new_environments):
            hazardous.append(f"{address}: {reason}")
        for attribute in ("name", "visibility", "archived"):
            if before.get(attribute) != after.get(attribute) and (
                attribute in before or attribute in after
            ):
                sensitive_changes.append(f"{address}: {attribute}")

    print("#### Resource action counts")
    if counts:
        for action, count in sorted(counts.items()):
            print(f"- `{action}`: {count}")
    else:
        print("- No resource changes")

    print("\n#### Protected attribute review")
    print("- Blocked actions or environment protection changes present: " + ("yes" if hazardous else "no"))
    print(
        "- Rename/visibility/archive changes present: "
        + ("yes" if sensitive_changes else "no")
    )
    if hazardous:
        print("\nPlan blocked: removal, replacement, or environment protection changes require separate operator review. Do not apply unclear provider transitions.")
        for item in hazardous:
            print(f"- `{item}`")
    if sensitive_changes:
        print("\nAttribute changes requiring operator review:")
        for item in sensitive_changes:
            print(f"- `{item}`")

    return 1 if hazardous else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, TypeError, KeyError, AttributeError) as error:
        print(f"Could not read plan JSON: {error.__class__.__name__}", file=sys.stderr)
        raise SystemExit(2)
