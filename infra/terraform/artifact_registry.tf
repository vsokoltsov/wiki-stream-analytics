resource "google_artifact_registry_repository" "repo" {
  depends_on = [google_project_service.artifactregistry]

  project       = var.project_id
  location      = var.region
  repository_id = "wiki-stream-analytics"
  description   = "Docker images for wiki-stream-analytics"
  format        = "DOCKER"
}