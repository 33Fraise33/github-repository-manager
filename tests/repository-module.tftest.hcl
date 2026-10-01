mock_provider "github" {}

variables {
  name                        = "example-public-repository"
  description                 = "Placeholder public repository."
  visibility                  = "public"
  topics                      = ["example", "public"]
  homepage                    = "https://example.invalid/example-public-repository"
  archived                    = false
  has_issues                  = true
  has_discussions             = false
  has_projects                = false
  has_wiki                    = false
  default_branch              = "main"
  delete_branch_on_merge      = true
  allow_squash_merge          = true
  allow_merge_commit          = true
  allow_rebase_merge          = true
  allow_auto_merge            = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  vulnerability_alerts        = true
  dependabot_security_updates = true
}

run "public_repository_settings_without_content" {
  command = plan

  module {
    source = "./modules/repository"
  }

  assert {
    condition     = length(github_repository_environment.this) == 0 && length(github_repository_environment_deployment_policy.this) == 0 && length(github_actions_environment_variable.this) == 0
    error_message = "Omitted environments must create no environment-related resources."
  }

  assert {
    condition = (
      github_repository.this.name == var.name &&
      github_repository.this.description == var.description &&
      github_repository.this.topics == toset(var.topics) &&
      github_repository.this.homepage_url == var.homepage &&
      github_repository.this.visibility == "public" &&
      !github_repository.this.archived &&
      !github_repository.this.auto_init &&
      github_repository.this.default_branch == "main" &&
      github_repository.this.has_issues &&
      !github_repository.this.has_discussions &&
      !github_repository.this.has_projects &&
      !github_repository.this.has_wiki
    )
    error_message = "Public repository metadata and features must be managed without initializing content."
  }

  assert {
    condition = (
      github_repository.this.allow_auto_merge &&
      github_repository.this.allow_merge_commit &&
      github_repository.this.allow_rebase_merge &&
      github_repository.this.allow_squash_merge &&
      github_repository.this.delete_branch_on_merge &&
      github_repository.this.squash_merge_commit_title == "PR_TITLE" &&
      github_repository.this.squash_merge_commit_message == "PR_BODY" &&
      github_repository_vulnerability_alerts.this.repository == var.name &&
      github_repository_vulnerability_alerts.this.enabled &&
      github_repository_dependabot_security_updates.this.repository == var.name &&
      github_repository_dependabot_security_updates.this.enabled
    )
    error_message = "Merge policy and both Dependabot settings must reach the provider resources."
  }

  assert {
    condition = (
      can(regex("prevent_destroy\\s*=\\s*true", file("${path.root}/main.tf"))) &&
      can(regex("prevent_destroy\\s*=\\s*true", file("${path.root}/ruleset.tf")))
    )
    error_message = "Repository and ruleset resources must retain literal destruction protection."
  }

  assert {
    condition = (
      github_repository_ruleset.default_branch["public"].repository == var.name &&
      github_repository_ruleset.default_branch["public"].target == "branch" &&
      github_repository_ruleset.default_branch["public"].enforcement == "active" &&
      join(",", github_repository_ruleset.default_branch["public"].conditions[0].ref_name[0].include) == "~DEFAULT_BRANCH" &&
      length(github_repository_ruleset.default_branch["public"].conditions[0].ref_name[0].exclude) == 0 &&
      github_repository_ruleset.default_branch["public"].rules[0].deletion &&
      github_repository_ruleset.default_branch["public"].rules[0].non_fast_forward &&
      github_repository_ruleset.default_branch["public"].rules[0].pull_request[0].required_approving_review_count == 0 &&
      github_repository_ruleset.default_branch["public"].rules[0].pull_request[0].required_review_thread_resolution &&
      toset(github_repository_ruleset.default_branch["public"].rules[0].pull_request[0].allowed_merge_methods) == toset(["merge", "squash", "rebase"]) &&
      length(github_repository_ruleset.default_branch["public"].bypass_actors) == 0 &&
      length(github_repository_ruleset.default_branch["public"].rules[0].required_status_checks) == 0
    )
    error_message = "Public repositories must receive only the fixed active default-branch protection policy."
  }
}

run "multiple_nonsecret_environments" {
  command = plan
  module { source = "./modules/repository" }
  variables {
    environments = {
      production = {
        name                = "Production"
        reviewers           = [101, 102]
        prevent_self_review = true
        wait_timer          = 30
        can_admins_bypass   = false
        deployment_mode     = "custom"
        deployment_rules = {
          release-branch = { type = "branch", pattern = "release/*" }
          release-tag    = { type = "tag", pattern = "v*" }
        }
        variables = { REGION = "example-region" }
      }
      staging = { name = "Staging", deployment_mode = "protected", can_admins_bypass = true }
      preview = { name = "Preview" }
    }
  }
  assert {
    condition = (
      toset(keys(github_repository_environment.this)) == toset(["production", "staging", "preview"]) &&
      alltrue([for env in values(github_repository_environment.this) : env.repository == var.name]) &&
      github_repository_environment.this["production"].environment == "Production" &&
      github_repository_environment.this["production"].wait_timer == 30 &&
      github_repository_environment.this["production"].prevent_self_review &&
      !github_repository_environment.this["production"].can_admins_bypass &&
      github_repository_environment.this["production"].reviewers[0].users == toset([101, 102]) &&
      github_repository_environment.this["production"].deployment_branch_policy[0].custom_branch_policies &&
      !github_repository_environment.this["production"].deployment_branch_policy[0].protected_branches &&
      github_repository_environment.this["staging"].deployment_branch_policy[0].protected_branches &&
      !github_repository_environment.this["staging"].deployment_branch_policy[0].custom_branch_policies &&
      github_repository_environment.this["staging"].can_admins_bypass &&
      length(github_repository_environment.this["preview"].deployment_branch_policy) == 0
    )
    error_message = "Stable environment keys and all supported protections must reach repository-scoped provider resources."
  }
  assert {
    condition = (
      github_repository_environment_deployment_policy.this["production/release-branch"].branch_pattern == "release/*" &&
      github_repository_environment_deployment_policy.this["production/release-tag"].tag_pattern == "v*" &&
      alltrue([for rule in values(github_repository_environment_deployment_policy.this) : rule.repository == var.name && rule.environment == "Production"]) &&
      github_actions_environment_variable.this["production/REGION"].repository == var.name &&
      github_actions_environment_variable.this["production/REGION"].environment == "Production" &&
      github_actions_environment_variable.this["production/REGION"].variable_name == "REGION" &&
      github_actions_environment_variable.this["production/REGION"].value == "example-region"
    )
    error_message = "Stable rule and variable addresses must be isolated to their repository and environment."
  }
  assert {
    condition     = length(regexall("prevent_destroy\\s*=\\s*true", file("${path.root}/environments.tf"))) == 3
    error_message = "All three environment resource types must retain literal prevent_destroy protection."
  }
}

run "explicit_empty_environments" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = {} }
  assert {
    condition     = length(github_repository_environment.this) == 0
    error_message = "Explicit empty environments must remain opt-out."
  }
}

run "environment_boundary_values" {
  command = plan
  module { source = "./modules/repository" }
  variables {
    environments = {
      stable-key = {
        name       = join("", [for _ in range(255) : "a"])
        reviewers  = [1, 2, 3, 4, 5, 6]
        wait_timer = 43200
        variables = merge({ for i in range(99) : "VAR_${i}" => "example" }, {
          MAX_BYTES = join("", [for _ in range(24) : join("", [for _ in range(1024) : "é"])])
        })
      }
    }
  }
  assert {
    condition = (
      toset(keys(github_repository_environment.this)) == toset(["stable-key"]) &&
      github_repository_environment.this["stable-key"].wait_timer == 43200 &&
      length(github_actions_environment_variable.this) == 100 &&
      length(base64encode(github_actions_environment_variable.this["stable-key/MAX_BYTES"].value)) == 65536
    )
    error_message = "Inclusive API limits must work, including 48 KiB UTF-8 values and keys independent of names."
  }
}

run "reject_negative_timer" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", wait_timer = -1 } } }
  expect_failures = [var.environments]
}

run "reject_fractional_timer" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", wait_timer = 1.5 } } }
  expect_failures = [var.environments]
}

run "reject_private_environments" {
  command = plan
  module { source = "./modules/repository" }
  variables {
    visibility       = "private"
    allow_auto_merge = false
    environments     = { production = { name = "Production" } }
  }
  expect_failures = [var.environments]
}

run "reject_duplicate_environment_names" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { first = { name = "Prod" }, second = { name = "prod" } } }
  expect_failures = [var.environments]
}

run "reject_invalid_environment_key_and_name" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { "Bad/Key" = { name = " " } } }
  expect_failures = [var.environments]
}

run "reject_oversized_environment_name" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = join("", [for _ in range(256) : "a"]) } } }
  expect_failures = [var.environments]
}

run "reject_invalid_reviewer_ids_and_timer" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", reviewers = [-1, 1.5], wait_timer = 43201 } } }
  expect_failures = [var.environments]
}

run "reject_more_than_six_reviewers" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", reviewers = [1, 2, 3, 4, 5, 6, 7] } } }
  expect_failures = [var.environments]
}

run "reject_self_review_without_reviewers" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", prevent_self_review = true } } }
  expect_failures = [var.environments]
}

run "reject_unsupported_protections" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", reviewer_teams = [1], custom_protection_rules = [2] } } }
  expect_failures = [var.environments]
}

run "reject_empty_custom_rules" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", deployment_mode = "custom" } } }
  expect_failures = [var.environments]
}

run "reject_rules_in_all_mode" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", deployment_rules = { main = { type = "branch", pattern = "main" } } } } }
  expect_failures = [var.environments]
}

run "reject_invalid_rule_and_duplicate_pattern" {
  command = plan
  module { source = "./modules/repository" }
  variables {
    environments = { production = { name = "Prod", deployment_mode = "custom", deployment_rules = {
      first = { type = "branch", pattern = "main" }, second = { type = "branch", pattern = "main" }, third = { type = "unsupported", pattern = "" }
    } } }
  }
  expect_failures = [var.environments]
}

run "reject_invalid_variable_names" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", variables = { GITHUB_RESERVED = "example", lower = "example", "1DIGIT" = "example" } } } }
  expect_failures = [var.environments]
}

run "reject_variable_limits" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", variables = { for i in range(101) : "VAR_${i}" => "example" } } } }
  expect_failures = [var.environments]
}

run "reject_oversized_variable_bytes" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", variables = { VALUE = join("", [for _ in range(49) : join("", [for _ in range(1024) : "é"])]) } } } }
  expect_failures = [var.environments]
}

run "reject_credential_signature_variable" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", variables = { VALUE = "api_key=synthetic-placeholder" } } } }
  expect_failures = [var.environments]
}

run "reject_valid_secret_references_pending_task07b" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", secret_refs = { DEPLOY_CREDENTIAL = { vault = "<vault>", item = "<item>", field = "<field>" } } } } }
  expect_failures = [var.environments]
}

run "reject_invalid_secret_reference_metadata" {
  command = plan
  module { source = "./modules/repository" }
  variables { environments = { production = { name = "Prod", secret_refs = { GITHUB_RESERVED = { vault = "", item = "<item>", field = "<field>" } } } } }
  expect_failures = [var.environments]
}

run "private_repository_can_be_explicitly_archived" {
  command = plan

  module {
    source = "./modules/repository"
  }

  variables {
    name             = "example-private-repository"
    visibility       = "private"
    archived         = true
    allow_auto_merge = false
    homepage         = null
  }

  assert {
    condition = (
      github_repository.this.visibility == "private" &&
      github_repository.this.archived &&
      !github_repository.this.allow_auto_merge &&
      !github_repository.this.auto_init &&
      !github_repository.this.has_wiki &&
      github_repository_dependabot_security_updates.this.enabled
    )
    error_message = "Private archival must remain explicit with GitHub Free-compatible settings and no content initialization."
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch) == 0
    error_message = "Private repositories must not receive rulesets while the account uses GitHub Free."
  }
}
