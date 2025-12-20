variable "project_id" {
  description = "The Google Cloud Project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The Google Cloud region for resources (e.g., us-central1)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The Google Cloud zone for resources (e.g., us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

variable "app_name" {
  description = "The name of the application"
  type        = string
  default     = "gke-devops-app"
}

variable "github_owner" {
  description = "Your GitHub username (e.g., franklin-dev)"
  type        = string
}

variable "github_repo" {
  description = "Your GitHub repository name (e.g., gke-devops-app)"
  type        = string
}