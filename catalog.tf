variable "repositories" {
  description = "Repositories keyed by stable logical identifier."

  type = map(object({
    name        = string
    description = string
    visibility  = string
    topics      = set(string)
    homepage    = optional(string)
    features = optional(object({
      issues        = optional(bool, true)
      discussions   = optional(bool, false)
      justification = optional(string)
    }), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.repositories) : can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", key))
    ])
    error_message = "Repository catalog keys must be stable lowercase identifiers containing only letters, numbers, and hyphens."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : length(repository.name) <= 100 && can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$", repository.name))
    ])
    error_message = "Repository names must be lowercase words separated by single hyphens, without repeated or trailing hyphens, and at most 100 characters."
  }

  validation {
    condition     = length(distinct([for repository in values(var.repositories) : repository.name])) == length(var.repositories)
    error_message = "Repository names must be unique across the catalog."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : contains(["public", "private"], repository.visibility)
    ])
    error_message = "Repository visibility must be public or private."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : length(repository.topics) <= 20 && alltrue([
        for topic in repository.topics : can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$", topic)) && length(topic) <= 50
      ])
    ])
    error_message = "Topics must be lowercase words separated by single hyphens, at most 50 characters each, with no more than 20 per repository."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : repository.homepage == null || can(regex("^https://[^[:space:]]+$", repository.homepage))
    ])
    error_message = "Homepage values must be HTTPS URLs."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : (
        (repository.features.issues && !repository.features.discussions) ||
        (repository.features.justification != null && length(trimspace(repository.features.justification)) > 0)
      )
    ])
    error_message = "Changing the default issues or discussions setting requires a non-empty feature override justification."
  }

  validation {
    condition = !can(regex(
      "(?i)(github_pat_[a-z0-9_]{20,}|gh[pousr]_[a-z0-9_]{20,}|-----begin [a-z ]*private key-----|(?:api[_-]?key|secret|token|password|private[_-]?key)[[:space:]]*[:=])",
      jsonencode(var.repositories),
    ))
    error_message = "Repository catalog entries must not contain credentials, private keys, or secret assignments."
  }
}

locals {
  repository_defaults = {
    default_branch              = "main"
    has_issues                  = true
    has_projects                = false
    has_wiki                    = false
    has_discussions             = false
    delete_branch_on_merge      = true
    allow_squash_merge          = true
    allow_merge_commit          = true
    allow_rebase_merge          = true
    allow_auto_merge            = true
    squash_merge_commit_title   = "PR_TITLE"
    squash_merge_commit_message = "PR_BODY"
  }

  public_default_branch_ruleset = {
    name                            = "protect-default-branch"
    enforcement                     = "active"
    target                          = "branch"
    ref_name_include                = ["~DEFAULT_BRANCH"]
    prevent_branch_deletion         = true
    prevent_force_pushes            = true
    require_pull_request            = true
    require_thread_resolution       = true
    required_approving_review_count = 0
    dismiss_stale_reviews_on_push   = true
    require_code_owner_review       = false
    require_last_push_approval      = false
    allowed_merge_methods           = ["merge", "squash", "rebase"]
  }

  repositories = {
    for key, repository in var.repositories : key => merge(repository, {
      features = merge({
        issues      = local.repository_defaults.has_issues
        discussions = local.repository_defaults.has_discussions
      }, repository.features)
    })
  }
}
