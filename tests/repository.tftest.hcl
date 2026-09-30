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
