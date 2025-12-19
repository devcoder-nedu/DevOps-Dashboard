provider "google" {
  project = var.project_id
  region  = var.region
}

# to enable APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "artifactregistry.googleapis.com"
  ])
  service = each.key
}

# 2. Artifact Registry
resource "google_artifact_registry_repository" "app_repo" {
  location      = var.zone
  repository_id = "${var.app_name}-repo"
  format        = "DOCKER"
}

# The staging cluster with 1 node
module "gke_staging" {
  source = "./modules/gke-cluster"

  project_id   = var.project_id
  region       = var.region
  cluster_name = "staging-cluster"
  node_count   = 1
  machine_type = "e2-medium"

  depends_on = [google_project_service.apis]
}

# The production cluster with 2 nodes
module "gke_prod" {
  source = "./modules/gke-cluster"

  project_id   = var.project_id
  region       = var.region
  cluster_name = "prod-cluster"
  node_count   = 2
  machine_type = "e2-medium"

  depends_on = [google_project_service.apis]
}

# cloud deploy targets
resource "google_clouddeploy_target" "staging" {
  name     = "staging"
  location = var.zone

  gke {
    cluster = module.gke_staging.cluster_id
  }
}

resource "google_clouddeploy_target" "prod" {
  name     = "prod"
  location = var.zone

  gke {
    cluster = module.gke_prod.cluster_id
  }

  # Require manual approval for prod
  require_approval = true
}

#  The cloud deploy delivery pipeline
resource "google_clouddeploy_delivery_pipeline" "pipeline" {
  name        = "${var.app_name}-pipeline"
  location    = var.zone
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
# Output variables to help with configuration

# IAM Bindings for Cloud Build Service Account
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_iam_member" "cloudbuild_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}


resource "google_project_iam_member" "cloudbuild_deploy_releaser" {
  project = var.project_id
  role    = "roles/clouddeploy.releaser"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Granted Cloud Build permission to "Act As" other Service Accounts
# (Required to trigger the Cloud Deploy execution)
resource "google_project_iam_member" "cloudbuild_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# 5. Grant the "Execution Service Account" permission to modify GKE
# (Cloud Deploy uses the Compute Engine Default SA by default to update clusters)
resource "google_project_iam_member" "deploy_container_dev" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}