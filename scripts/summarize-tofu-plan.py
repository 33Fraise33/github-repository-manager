#!/usr/bin/env python3
"""Print a sanitized OpenTofu plan summary and reject destructive actions."""

import json
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: summarize-tofu-plan.py PLAN_JSON", file=sys.stderr)
        return 2

    with open(sys.argv[1], encoding="utf-8") as plan_file:
        plan = json.load(plan_file)

    counts: dict[str, int] = {}
    hazardous: list[str] = []
    sensitive_changes: list[str] = []
    for resource in plan.get("resource_changes", []):
        change = resource.get("change", {})
        actions = change.get("actions", [])
        action = "+".join(actions) if actions else "no-op"
        counts[action] = counts.get(action, 0) + 1
        before = change.get("before") or {}
        after = change.get("after") or {}
        address = resource.get("address", "unknown resource")

        if any(item in actions for item in ("delete", "forget")):
            hazardous.append(f"{address}: {action}")
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
    print("- Deletion/replacement present: " + ("yes" if hazardous else "no"))
    print(
        "- Rename/visibility/archive changes present: "
        + ("yes" if sensitive_changes else "no")
    )
    if hazardous:
        print("\nPlan blocked: deletion or replacement requires separate operator review.")
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
    except (OSError, json.JSONDecodeError) as error:
        print(f"Could not read plan JSON: {error.__class__.__name__}", file=sys.stderr)
        raise SystemExit(2)
