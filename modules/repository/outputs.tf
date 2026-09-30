output "id" {
  description = "GitHub numeric repository ID."
  value       = github_repository.this.repo_id
}

output "web_url" {
  description = "Repository web URL."
  value       = github_repository.this.html_url
}

output "https_url" {
  description = "HTTPS clone URL."
  value       = github_repository.this.http_clone_url
}

output "ssh_url" {
  description = "SSH clone URL."
  value       = github_repository.this.ssh_clone_url
}

output "name" {
  description = "Repository name."
  value       = github_repository.this.name
}

output "visibility" {
  description = "Repository visibility."
  value       = github_repository.this.visibility
}
