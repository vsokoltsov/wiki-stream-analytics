module "bootstrap" {
  source = "./modules/bootstrap"

  project_id = var.project_id
}

moved {
  from = google_project_service.artifactregistry
  to   = module.bootstrap.google_project_service.artifactregistry
}

moved {
  from = google_project_service.cloudbuild
  to   = module.bootstrap.google_project_service.cloudbuild
}

moved {
  from = google_project_service.iam
  to   = module.bootstrap.google_project_service.iam
}

moved {
  from = google_project_service.serviceusage
  to   = module.bootstrap.google_project_service.serviceusage
}

moved {
  from = google_project_service.compute
  to   = module.bootstrap.google_project_service.compute
}

moved {
  from = google_project_service.managedkafka
  to   = module.bootstrap.google_project_service.managedkafka
}

moved {
  from = google_project_service.gke
  to   = module.bootstrap.google_project_service.gke
}

moved {
  from = google_project_service.secretmanager
  to   = module.bootstrap.google_project_service.secretmanager
}

moved {
  from = google_project_service.storage
  to   = module.bootstrap.google_project_service.storage
}

moved {
  from = google_project_service.pubsub
  to   = module.bootstrap.google_project_service.pubsub
}

moved {
  from = google_project_service.bigquery
  to   = module.bootstrap.google_project_service.bigquery
}

moved {
  from = google_project_service.cloudresourcemanager
  to   = module.bootstrap.google_project_service.cloudresourcemanager
}

moved {
  from = google_project_service.dataflow
  to   = module.bootstrap.google_project_service.dataflow
}
