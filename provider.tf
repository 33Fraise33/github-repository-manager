provider "github" {
  owner         = "33Fraise33"
  legacy_client = false
}

data "github_user" "current" {
  username = ""

  lifecycle {
    postcondition {
      condition     = lower(self.login) == "33fraise33"
      error_message = "GITHUB_TOKEN must authenticate as the managed GitHub account 33Fraise33."
    }
  }
}
