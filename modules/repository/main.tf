resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage
  visibility   = var.visibility
  topics       = var.topics

  auto_init      = false
  archived       = var.archived
  default_branch = var.default_branch

  has_issues      = var.has_issues
  has_discussions = var.has_discussions
  has_projects    = var.has_projects
  has_wiki        = var.has_wiki

  delete_branch_on_merge      = var.delete_branch_on_merge
  allow_squash_merge          = var.allow_squash_merge
  allow_merge_commit          = var.allow_merge_commit
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge
  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = var.vulnerability_alerts
}

resource "github_repository_dependabot_security_updates" "this" {
  repository = github_repository.this.name
  enabled    = var.dependabot_security_updates

  depends_on = [github_repository_vulnerability_alerts.this]
}
