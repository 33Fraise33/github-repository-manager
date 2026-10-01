"""Credential-free synthetic plan review and redaction regression tests."""

import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/summarize-tofu-plan.py"
ENVIRONMENT = "github_repository_environment"
POLICY = "github_repository_environment_deployment_policy"
VARIABLE = "github_actions_environment_variable"
CANARY = "SYNTHETIC_VALUE_MUST_NOT_APPEAR_07A"


def environment():
    return {
        "repository": "example-repository", "environment": "Production",
        "reviewers": [{"users": [101, 102], "teams": []}], "wait_timer": 30,
        "prevent_self_review": True, "can_admins_bypass": False,
        "deployment_branch_policy": [{"protected_branches": False, "custom_branch_policies": True}],
    }


def resource(kind, before, after, actions=None, unknown=None):
    return {
        "type": kind, "address": CANARY,
        "change": {"before": before, "after": after, "actions": actions or ["update"], "after_unknown": unknown or {}},
    }


class PlanSummaryTests(unittest.TestCase):
    def summarize(self, resources, expected, omit_resource_changes=False):
        plan = {"format_version": "1.2", "terraform_version": "1.12.6", "variables": {"references": CANARY}, "outputs": {"canary": CANARY}}
        if not omit_resource_changes:
            plan["resource_changes"] = resources
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "plan.json"
            path.write_text(json.dumps(plan), encoding="utf-8")
            result = subprocess.run([sys.executable, str(SCRIPT), str(path)], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        self.assertNotIn(CANARY, result.stdout + result.stderr)
        return result.stdout

    def test_empty_and_noop(self):
        self.summarize([], 0)
        self.summarize([resource(ENVIRONMENT, environment(), environment(), ["no-op"])], 0)

    def test_omitted_resource_changes_is_empty(self):
        summary = self.summarize([], 0, omit_resource_changes=True)
        self.assertIn("- No resource changes", summary)

    def test_malformed_present_resource_changes_is_rejected(self):
        for value in (None, {}, CANARY, 0, False):
            with self.subTest(value=value):
                self.summarize(value, 2)

    def test_initial_environment_rules_and_variable(self):
        rule = {"repository": "example-repository", "environment": "Production", "branch_pattern": "main", "tag_pattern": None}
        variable = dict(rule, variable_name="REGION", value=CANARY)
        self.summarize([
            resource(ENVIRONMENT, None, environment(), ["create"]),
            resource(POLICY, None, rule, ["create"]),
            resource(VARIABLE, None, variable, ["create"]),
        ], 0)

    def test_safe_strengthening_and_variable_value_update(self):
        after = dict(environment(), wait_timer=60)
        self.summarize([resource(ENVIRONMENT, environment(), after)], 0)
        before = {"repository": "example-repository", "environment": "Production", "variable_name": "REGION", "value": "old"}
        self.summarize([resource(VARIABLE, before, dict(before, value=CANARY))], 0)

    def test_each_protection_weakening(self):
        changes = {
            "shorter_wait": {"wait_timer": 20},
            "clear_wait": {"wait_timer": 0},
            "remove_reviewer": {"reviewers": [{"users": [101], "teams": []}]},
            "clear_reviewers": {"reviewers": []},
            "add_eligible_approver": {"reviewers": [{"users": [101, 102, 103], "teams": []}]},
            "self_review": {"prevent_self_review": False},
            "bypass": {"can_admins_bypass": True},
            "broader_mode": {"deployment_branch_policy": []},
            "unclear_mode": {"deployment_branch_policy": [{"protected_branches": True, "custom_branch_policies": False}]},
            "rename": {"environment": "New-name"},
            "scope": {"repository": "other-repository"},
        }
        for name, attrs in changes.items():
            with self.subTest(name=name):
                self.summarize([resource(ENVIRONMENT, environment(), dict(environment(), **attrs))], 1)

    def test_removal_replacement_and_forget(self):
        for kind in (ENVIRONMENT, POLICY, VARIABLE, "github_repository"):
            for actions in (["delete"], ["delete", "create"], ["create", "delete"], ["forget"]):
                with self.subTest(kind=kind, actions=actions):
                    self.summarize([resource(kind, environment(), environment(), actions)], 1)

    def test_unknown_protection_fields(self):
        for attr in ("wait_timer", "reviewers", "prevent_self_review", "can_admins_bypass", "deployment_branch_policy", "repository", "environment"):
            with self.subTest(attribute=attr):
                self.summarize([resource(ENVIRONMENT, environment(), environment(), unknown={attr: True})], 1)
                self.summarize([resource(ENVIRONMENT, None, environment(), ["create"], unknown={attr: True})], 1)
        self.summarize([resource(ENVIRONMENT, environment(), environment(), unknown={"reviewers": [{"users": [True]}]})], 1)

    def test_incomplete_evidence(self):
        before = environment()
        del before["wait_timer"]
        self.summarize([resource(ENVIRONMENT, before, environment())], 1)
        self.summarize([resource(ENVIRONMENT, None, before, ["create"])], 1)
        self.summarize([resource(ENVIRONMENT, environment(), environment(), ["unexpected"])], 2)
        missing_type = resource(ENVIRONMENT, environment(), environment())
        del missing_type["type"]
        self.summarize([missing_type], 2)

    def test_policy_changes_and_addition_on_existing_environment(self):
        before = {"repository": "example-repository", "environment": "Production", "branch_pattern": "main", "tag_pattern": None}
        self.summarize([resource(POLICY, before, dict(before, branch_pattern="*"))], 1)
        self.summarize([resource(POLICY, None, before, ["create"])], 1)
        self.summarize([resource(POLICY, before, copy.deepcopy(before), unknown={"branch_pattern": True})], 1)

    def test_variable_rename(self):
        before = {"repository": "example-repository", "environment": "Production", "variable_name": "REGION", "value": CANARY}
        self.summarize([resource(VARIABLE, before, dict(before, variable_name="NEW_REGION"))], 1)


if __name__ == "__main__":
    unittest.main()
