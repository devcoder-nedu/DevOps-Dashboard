output "artifact_repo" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.name}"
}
output "staging_cluster_name" {
  value = module.gke_staging.cluster_name
}

output "prod_cluster_name" {
  value = module.gke_prod.cluster_name
}

output "staging_cluster_id" {
  value = module.gke_staging.cluster_id
}

output "prod_cluster_id" {
  value = module.gke_prod.cluster_id
}

output "staging_clouddeploy_target" {
  value = google_clouddeploy_target.staging.name
}


