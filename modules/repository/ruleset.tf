resource "github_repository_ruleset" "default_branch" {
  for_each = var.visibility == "public" ? { public = true } : {}

  name        = "default-branch-protection"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = 0
      required_review_thread_resolution = true
      allowed_merge_methods             = ["merge", "squash", "rebase"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
