variable "name" {
  description = "Repository name."
  type        = string
}

variable "description" {
  description = "Repository description."
  type        = string
}

variable "visibility" {
  description = "Repository visibility."
  type        = string
}

variable "topics" {
  description = "Repository topics."
  type        = set(string)
}

variable "homepage" {
  description = "Optional repository homepage URL."
  type        = string
  default     = null
  nullable    = true
}

variable "archived" {
  description = "Whether the repository is archived."
  type        = bool
}

variable "has_issues" {
  description = "Whether GitHub Issues is enabled."
  type        = bool
}

variable "has_discussions" {
  description = "Whether GitHub Discussions is enabled."
  type        = bool
}

variable "has_projects" {
  description = "Whether repository projects are enabled."
  type        = bool
}

variable "has_wiki" {
  description = "Whether the repository wiki is enabled."
  type        = bool
}

variable "default_branch" {
  description = "Repository default branch name."
  type        = string
}

variable "delete_branch_on_merge" {
  description = "Whether to delete pull request head branches after merge."
  type        = bool
}

variable "allow_squash_merge" {
  description = "Whether squash merges are allowed."
  type        = bool
}

variable "allow_merge_commit" {
  description = "Whether merge commits are allowed."
  type        = bool
}

variable "allow_rebase_merge" {
  description = "Whether rebase merges are allowed."
  type        = bool
}

variable "allow_auto_merge" {
  description = "Whether pull request auto-merge is enabled."
  type        = bool
}

variable "squash_merge_commit_title" {
  description = "Default title format for squash merge commits."
  type        = string
}

variable "squash_merge_commit_message" {
  description = "Default message format for squash merge commits."
  type        = string
}

variable "vulnerability_alerts" {
  description = "Whether Dependabot vulnerability alerts are enabled."
  type        = bool
}

variable "dependabot_security_updates" {
  description = "Whether Dependabot automated security updates are enabled."
  type        = bool
}
