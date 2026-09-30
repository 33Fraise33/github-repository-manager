# Catalog validation is exercised with a mocked provider and plan-only runs.
mock_provider "github" {
  mock_data "github_user" {
    defaults = {
      login = "33Fraise33"
    }
  }
}

run "rejects_invalid_catalog_key" {
  command = plan
  variables {
    repositories = {
      "Invalid-Key" = {
        name        = "valid-name"
        description = "Placeholder."
        visibility  = "public"
        topics      = []
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_malformed_repository_name" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "Bad--Name"
        description = "Placeholder."
        visibility  = "public"
        topics      = []
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_repository_name_over_100_characters" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "${join("", [for _ in range(0, 101) : "a"])}"
        description = "Placeholder."
        visibility  = "public"
        topics      = []
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_duplicate_repository_names" {
  command = plan
  variables {
    repositories = {
      first = {
        name        = "same-name"
        description = "Placeholder."
        visibility  = "public"
        topics      = []
        archived    = false
      }
      second = {
        name        = "same-name"
        description = "Placeholder."
        visibility  = "private"
        topics      = []
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_unsupported_visibility" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "valid-name"
        description = "Placeholder."
        visibility  = "internal"
        topics      = []
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_malformed_topic" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "valid-name"
        description = "Placeholder."
        visibility  = "public"
        topics      = ["Not_Normalized"]
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_topic_longer_than_50_characters" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "valid-name"
        description = "Placeholder."
        visibility  = "public"
        topics      = [join("", [for _ in range(0, 51) : "a"])]
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_more_than_20_topics" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "valid-name"
        description = "Placeholder."
        visibility  = "public"
        topics      = [for index in range(0, 21) : "topic-${index}"]
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_non_https_homepage" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "valid-name"
        description = "Placeholder."
        visibility  = "public"
        topics      = []
        archived    = false
        homepage    = "http://example.invalid"
      }
    }
  }
  expect_failures = [var.repositories]
}

run "requires_justification_for_feature_override" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "valid-name"
        description = "Placeholder."
        visibility  = "public"
        topics      = []
        archived    = false
        features = {
          issues = false
        }
      }
    }
  }
  expect_failures = [var.repositories]
}

run "rejects_secret_signatures_in_catalog" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "valid-name"
        description = "api_key=synthetic-placeholder"
        visibility  = "public"
        topics      = []
        archived    = false
      }
    }
  }
  expect_failures = [var.repositories]
}

run "accepts_boundary_values_and_justified_feature_override" {
  command = plan
  variables {
    repositories = {
      example = {
        name        = "${join("", [for _ in range(0, 100) : "a"])}"
        description = "Placeholder."
        visibility  = "private"
        topics      = [join("", [for _ in range(0, 50) : "a"])]
        archived    = false
        homepage    = "https://example.invalid"
        features = {
          discussions   = true
          justification = "Required for the documented pilot policy test."
        }
      }
    }
  }

  assert {
    condition     = output.repositories.example.visibility == "private"
    error_message = "A valid catalog entry at documented length boundaries must plan successfully."
  }
}
