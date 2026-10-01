module "repository" {
  for_each = local.repositories

  source = "./modules/repository"

  # GitHub Free supports auto-merge only for public repositories.
  name                        = each.value.name
  description                 = each.value.description
  visibility                  = each.value.visibility
  topics                      = each.value.topics
  homepage                    = each.value.homepage
  archived                    = each.value.archived
  environments                = each.value.environments
  has_issues                  = each.value.features.issues
  has_discussions             = each.value.features.discussions
  has_projects                = local.repository_defaults.has_projects
  has_wiki                    = local.repository_defaults.has_wiki
  default_branch              = local.repository_defaults.default_branch
  delete_branch_on_merge      = local.repository_defaults.delete_branch_on_merge
  allow_squash_merge          = local.repository_defaults.allow_squash_merge
  allow_merge_commit          = local.repository_defaults.allow_merge_commit
  allow_rebase_merge          = local.repository_defaults.allow_rebase_merge
  allow_auto_merge            = local.repository_defaults.allow_auto_merge && each.value.visibility == "public"
  squash_merge_commit_title   = local.repository_defaults.squash_merge_commit_title
  squash_merge_commit_message = local.repository_defaults.squash_merge_commit_message
  vulnerability_alerts        = local.repository_defaults.vulnerability_alerts
  dependabot_security_updates = local.repository_defaults.dependabot_security_updates

  depends_on = [data.github_user.current]
}

output "repositories" {
  description = "Managed repository details keyed by stable catalog identifier."

  value = {
    for key, repository in module.repository : key => {
      id         = repository.id
      web_url    = repository.web_url
      https_url  = repository.https_url
      ssh_url    = repository.ssh_url
      name       = repository.name
      visibility = repository.visibility
    }
  }
}
