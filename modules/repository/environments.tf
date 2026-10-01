variable "environments" {
  description = "Opt-in nonsecret environments keyed by stable logical identifiers. Secret references are blocked pending Task 07b."
  type = map(object({
    name                    = string
    reviewers               = optional(set(number), [])
    reviewer_teams          = optional(set(number), [])
    prevent_self_review     = optional(bool, false)
    wait_timer              = optional(number, 0)
    can_admins_bypass       = optional(bool, false)
    custom_protection_rules = optional(set(number), [])
    deployment_mode         = optional(string, "all")
    deployment_rules = optional(map(object({
      type    = string
      pattern = string
    })), {})
    variables = optional(map(string), {})
    secret_refs = optional(map(object({
      vault = string
      item  = string
      field = string
    })), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition     = var.visibility == "public" || length(var.environments) == 0
    error_message = "Personal GitHub Free does not support environments on private repositories; do not opt private repositories in."
  }
  validation {
    condition = alltrue([
      for key, env in var.environments : can(regex("^[a-z][a-z0-9-]*$", key)) &&
      length(env.name) > 0 && length(env.name) <= 255 && env.name == trimspace(env.name) &&
      !can(regex("[[:cntrl:]]", env.name))
    ]) && length(distinct([for env in values(var.environments) : lower(env.name)])) == length(var.environments)
    error_message = "Environment keys must be stable lowercase identifiers; names must be nonblank, trimmed, control-free, at most 255 characters, and case-insensitively unique per repository."
  }
  validation {
    condition = alltrue([
      for env in values(var.environments) : length(env.reviewers) <= 6 && alltrue([
        for id in env.reviewers : id > 0 && id == floor(id) && id <= 9007199254740991
      ]) && (!env.prevent_self_review || length(env.reviewers) > 0) &&
      env.wait_timer >= 0 && env.wait_timer <= 43200 && env.wait_timer == floor(env.wait_timer)
    ])
    error_message = "Use at most six positive integral user reviewer IDs, self-review prevention only with reviewers, and an integral wait timer from 0 through 43200 minutes."
  }
  validation {
    condition = alltrue([
      for env in values(var.environments) : length(env.reviewer_teams) == 0 && length(env.custom_protection_rules) == 0
    ])
    error_message = "Team reviewers are organization-only; custom GitHub App deployment protection rules are not supported by provider 6.13.0. Neither may be requested."
  }
  validation {
    condition = alltrue([
      for env in values(var.environments) : contains(["all", "protected", "custom"], env.deployment_mode) &&
      (env.deployment_mode == "custom" ? length(env.deployment_rules) > 0 : length(env.deployment_rules) == 0) && alltrue([
        for key, rule in env.deployment_rules : can(regex("^[a-z][a-z0-9-]*$", key)) &&
        contains(["branch", "tag"], rule.type) && length(trimspace(rule.pattern)) > 0 &&
        length(rule.pattern) <= 255 && !can(regex("[[:cntrl:]]", rule.pattern))
      ]) && length(distinct([for rule in values(env.deployment_rules) : jsonencode([rule.type, rule.pattern])])) == length(env.deployment_rules)
    ])
    error_message = "Deployment mode must be all, protected, or custom. Only custom requires stable-key branch/tag rules with unique nonblank control-free patterns of at most 255 characters."
  }
  validation {
    condition = alltrue([
      for env in values(var.environments) : length(env.variables) <= 100 && alltrue([
        for name, value in env.variables : can(regex("^[A-Z_][A-Z0-9_]*$", name)) &&
        !startswith(name, "GITHUB_") && length(base64encode(value)) <= 65536 &&
        !can(regex("(?i)(github_pat_[a-z0-9_]{20,}|gh[pousr]_[a-z0-9_]{20,}|-----begin [a-z ]*private key-----|(?:api[_-]?key|secret|token|password|private[_-]?key)[[:space:]]*[:=])", value))
      ])
    ])
    error_message = "Environment variables are nonsecret: at most 100, uppercase alphanumeric/underscore names not starting with a digit or GITHUB_, and values at most 48 KiB without credential signatures."
  }
  validation {
    condition = alltrue([
      for env in values(var.environments) : alltrue([
        for name, ref in env.secret_refs : can(regex("^[A-Z_][A-Z0-9_]*$", name)) && !startswith(name, "GITHUB_") && alltrue([
          for identifier in [ref.vault, ref.item, ref.field] : length(trimspace(identifier)) > 0 && !can(regex("[[:cntrl:]]", identifier))
        ])
      ])
    ])
    error_message = "Secret references contain only a valid uppercase secret name and nonblank control-free vault/item/field identifiers, never values."
  }
  validation {
    condition     = alltrue([for env in values(var.environments) : length(env.secret_refs) == 0])
    error_message = "Task 07b blocked: GitHub provider 6.13.0 has no write-only environment secret input. Remove secret_refs; no retrieval or secret writes are enabled."
  }
}

locals {
  environment_rules = merge({}, [for env_key, env in var.environments : {
    for rule_key, rule in env.deployment_rules : "${env_key}/${rule_key}" => merge(rule, { environment_key = env_key })
  }]...)
  environment_variables = merge({}, [for env_key, env in var.environments : {
    for name, value in env.variables : "${env_key}/${name}" => {
      environment_key = env_key
      name            = name
      value           = value
    }
  }]...)
}

resource "github_repository_environment" "this" {
  for_each = var.environments

  repository          = github_repository.this.name
  environment         = each.value.name
  wait_timer          = each.value.wait_timer
  prevent_self_review = each.value.prevent_self_review
  can_admins_bypass   = each.value.can_admins_bypass

  dynamic "reviewers" {
    for_each = length(each.value.reviewers) > 0 ? [each.value.reviewers] : []
    content {
      users = reviewers.value
    }
  }
  dynamic "deployment_branch_policy" {
    for_each = each.value.deployment_mode == "all" ? [] : [each.value.deployment_mode]
    content {
      protected_branches     = deployment_branch_policy.value == "protected"
      custom_branch_policies = deployment_branch_policy.value == "custom"
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_environment_deployment_policy" "this" {
  for_each = local.environment_rules

  repository     = github_repository.this.name
  environment    = github_repository_environment.this[each.value.environment_key].environment
  branch_pattern = each.value.type == "branch" ? each.value.pattern : null
  tag_pattern    = each.value.type == "tag" ? each.value.pattern : null
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_actions_environment_variable" "this" {
  for_each = local.environment_variables

  repository    = github_repository.this.name
  environment   = github_repository_environment.this[each.value.environment_key].environment
  variable_name = each.value.name
  value         = each.value.value
  lifecycle {
    prevent_destroy = true
  }
}
