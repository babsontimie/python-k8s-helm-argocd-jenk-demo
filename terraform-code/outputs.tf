output "cluster_name" { value = google_container_cluster.gke.name }
output "cluster_endpoint" { value = google_container_cluster.gke.endpoint }

output "artifact_registry_repo" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_name}"
}
