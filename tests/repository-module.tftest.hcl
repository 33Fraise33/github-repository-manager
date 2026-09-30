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
}
