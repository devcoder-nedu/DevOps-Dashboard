terraform {
  required_version = ">= 1.0"

  # 1. REMOTE STATE CONFIGURATION
  backend "gcs" {
    bucket = "gke-devops-terraform-state-strange-mariner-290720"
    prefix = "terraform/state"
  }

  # 2. PROVIDER UPGRADE
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Upgraded to version 5 to support modern features
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 3. ENABLE APIS
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com" # Added IAM API explicitly as we are creating Service Accounts
  ])
  service            = each.key
  disable_on_destroy = false
}

# ---------------------------------------------------------
# 4. SECURITY & PERMISSIONS (The Fix for Build Errors)
# ---------------------------------------------------------

# Create a dedicated Service Account for the Pipeline
resource "google_service_account" "pipeline_sa" {
  account_id   = "${var.app_name}-sa"
  display_name = "Cloud Build Pipeline Service Account"
  depends_on   = [google_project_service.apis]
}

# Grant "Log Writer" (Fixes the Logging error)
resource "google_project_iam_member" "sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Grant "Artifact Registry Writer" (Allows pushing Docker images)
resource "google_project_iam_member" "sa_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Grant "Cloud Deploy Releaser" (Allows creating releases)
resource "google_project_iam_member" "sa_deploy_releaser" {
  project = var.project_id
  role    = "roles/clouddeploy.releaser"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Grant "Service Account User" (Allows Cloud Build to run as this SA)
resource "google_project_iam_member" "sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Grant "Container Developer" (Allows updating GKE clusters)
resource "google_project_iam_member" "sa_container_dev" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Grant "Storage Admin" (Allows creating the Cloud Deploy bucket)
resource "google_project_iam_member" "sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# ---------------------------------------------------------
# 5. INFRASTRUCTURE RESOURCES
# ---------------------------------------------------------

# Artifact Registry
resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region
  repository_id = "${var.app_name}-repo"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# Staging Cluster
module "gke_staging" {
  source = "./modules/gke-cluster"

  project_id   = var.project_id
  region       = var.zone
  cluster_name = "staging-cluster"
  node_count   = 1
  machine_type = "e2-medium"

  # Resource Management
  disk_size_gb = 30
  disk_type    = "pd-standard"

  depends_on = [google_project_service.apis]
}

# Production Cluster
module "gke_prod" {
  source = "./modules/gke-cluster"

  project_id   = var.project_id
  region       = var.zone
  cluster_name = "prod-cluster"
  node_count   = 2
  machine_type = "e2-medium"

  # Resource Management
  disk_size_gb = 30
  disk_type    = "pd-standard"

  depends_on = [google_project_service.apis, module.gke_staging]
}

# ---------------------------------------------------------
# 6. DEPLOYMENT PIPELINE
# ---------------------------------------------------------

# Cloud Deploy Target: Staging
resource "google_clouddeploy_target" "staging" {
  name     = "staging"
  location = var.region

  gke {
    cluster = module.gke_staging.cluster_id
  }
}

# Cloud Deploy Target: Production
resource "google_clouddeploy_target" "prod" {
  name     = "prod"
  location = var.region

  gke {
    cluster = module.gke_prod.cluster_id
  }

  require_approval = true
}

# Delivery Pipeline Definition
resource "google_clouddeploy_delivery_pipeline" "pipeline" {
  name        = "${var.app_name}-pipeline"
  location    = var.region
  description = "Delivery pipeline for ${var.app_name}"
  project     = var.project_id

  serial_pipeline {
    stages {
      profiles  = ["staging"]
      target_id = google_clouddeploy_target.staging.name
    }
    stages {
      profiles  = ["prod"]
      target_id = google_clouddeploy_target.prod.name
    }
  }
}

# ---------------------------------------------------------
# 7. CI/CD TRIGGER (Using Custom Service Account)
# ---------------------------------------------------------

resource "google_cloudbuild_trigger" "react_trigger" {
  name     = "${var.app_name}-trigger"
  location = var.region

  # CRITICAL: Use the custom service account we created above
  service_account = google_service_account.pipeline_sa.id

  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _REGION        = var.region
    _PIPELINE_NAME = google_clouddeploy_delivery_pipeline.pipeline.name
    _REPO_NAME     = google_artifact_registry_repository.app_repo.name
  }

  depends_on = [
    google_artifact_registry_repository.app_repo,
    google_clouddeploy_delivery_pipeline.pipeline,
    google_project_iam_member.sa_user # Wait for permissions to propagate
  ]
}