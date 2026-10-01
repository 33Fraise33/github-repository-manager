# Every GitHub resource and data source is mocked. No aliases or real providers.
mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      repo_id        = 101
      html_url       = "https://example.invalid/mock-repository"
      http_clone_url = "https://example.invalid/mock-repository.git"
      ssh_clone_url  = "git@example.invalid:mock-repository.git"
    }
  }

  mock_data "github_user" {
    defaults = {
      login = "33Fraise33"
    }
  }
}

variables {
  repositories = {
    public-example = {
      name        = "example-public-repository"
      description = "Placeholder public repository."
      visibility  = "public"
      topics      = ["example", "public"]
      archived    = false
      homepage    = "https://example.invalid/example-public-repository"
    }
    private-example = {
      name        = "example-private-repository"
      description = "Placeholder private repository."
      visibility  = "private"
      topics      = ["example", "private"]
      archived    = false
    }
  }
}

run "sample_catalog_plans_from_empty_state" {
  command = plan

  assert {
    condition     = toset(keys(output.repositories)) == toset(["public-example", "private-example"])
    error_message = "The public/private sample must retain stable catalog keys as module output keys."
  }

  assert {
    condition = alltrue([
      for key, repository in var.repositories :
      output.repositories[key].name == repository.name &&
      output.repositories[key].visibility == repository.visibility
    ])
    error_message = "Each catalog entry must reach the corresponding repository module."
  }

  assert {
    condition = (
      local.repositories["public-example"].name == "example-public-repository" &&
      local.repositories["private-example"].name == "example-private-repository" &&
      local.repositories["public-example"].features.issues &&
      local.repositories["private-example"].features.issues &&
      !local.repositories["public-example"].features.discussions &&
      !local.repositories["private-example"].features.discussions &&
      local.repository_defaults.default_branch == "main" &&
      !local.repository_defaults.has_wiki &&
      !local.repository_defaults.has_discussions
    )
    error_message = "Stable catalog keys must wire repositories with the fixed main-branch and feature defaults."
  }

  assert {
    condition = (
      local.repository_defaults.delete_branch_on_merge &&
      local.repository_defaults.allow_squash_merge &&
      local.repository_defaults.allow_merge_commit &&
      local.repository_defaults.allow_rebase_merge &&
      local.repository_defaults.squash_merge_commit_title == "PR_TITLE" &&
      local.repository_defaults.squash_merge_commit_message == "PR_BODY"
    )
    error_message = "Root catalog wiring must apply the fixed merge policy and head-branch cleanup."
  }

  assert {
    condition = (
      local.repository_defaults.allow_auto_merge &&
      var.repositories["public-example"].visibility == "public" &&
      var.repositories["private-example"].visibility == "private"
    )
    error_message = "Auto-merge must follow GitHub Free availability for public and private repositories."
  }
}

run "empty_catalog_plans_without_repository_instances" {
  command = plan

  variables {
    repositories = {}
  }

  assert {
    condition     = length(output.repositories) == 0 && length(module.repository) == 0
    error_message = "An empty catalog must preserve an empty output and create no repository instances."
  }
}

run "environment_catalog_is_optional_and_repository_scoped" {
  command = plan
  variables {
    repositories = {
      first = {
        name         = "first-repository", description = "Placeholder.", visibility = "public", topics = [], archived = false
        environments = { production = { name = "Production", variables = { REGION = "first-region" } } }
      }
      second = {
        name         = "second-repository", description = "Placeholder.", visibility = "public", topics = [], archived = false
        environments = { production = { name = "Production", variables = { REGION = "second-region" } }, staging = { name = "Staging" } }
      }
      third = {
        name = "third-repository", description = "Placeholder.", visibility = "private", topics = [], archived = false
      }
    }
  }
  assert {
    condition = (
      local.repositories.first.environments.production.variables.REGION == "first-region" &&
      local.repositories.second.environments.production.variables.REGION == "second-region" &&
      length(local.repositories.second.environments) == 2 &&
      length(local.repositories.third.environments) == 0 &&
      length(output.repositories) == 3
    )
    error_message = "The root typed catalog must retain independent optional environment maps per stable repository key."
  }
}

run "justified_feature_override_reaches_repository" {
  command = plan

  variables {
    repositories = {
      justified-override = {
        name        = "justified-override"
        description = "Placeholder."
        visibility  = "public"
        topics      = []
        archived    = false
        features = {
          discussions   = true
          justification = "Exercise explicitly justified feature wiring."
        }
      }
    }
  }

  assert {
    condition = (
      local.repositories["justified-override"].features.issues &&
      local.repositories["justified-override"].features.discussions &&
      output.repositories["justified-override"].name == "justified-override"
    )
    error_message = "A justified catalog feature exception must reach only its stable-key repository instance."
  }
}

run "sample_catalog_outputs_are_provider_attributes" {
  command = plan

  assert {
    condition = alltrue([
      for key, repository in var.repositories :
      output.repositories[key].id == 101 &&
      output.repositories[key].web_url == "https://example.invalid/mock-repository" &&
      output.repositories[key].https_url == "https://example.invalid/mock-repository.git" &&
      output.repositories[key].ssh_url == "git@example.invalid:mock-repository.git" &&
      output.repositories[key].name == repository.name &&
      output.repositories[key].visibility == repository.visibility
    ])
    error_message = "All six outputs must expose the correct repository attributes by stable catalog key."
  }
}
