module "gke" {
  source = "./modules/gke"

  project_id               = var.project_id
  region                   = var.region
  network_name             = module.network.network_name
  subnetwork_name          = module.network.subnetwork_name
  ci_service_account_email = module.ci_cd.ci_service_account_email

  depends_on = [module.bootstrap]
}

moved {
  from = google_container_cluster.gke
  to   = module.gke.google_container_cluster.gke
}

moved {
  from = google_container_node_pool.primary
  to   = module.gke.google_container_node_pool.primary
}

moved {
  from = google_service_account.gke_nodes
  to   = module.gke.google_service_account.gke_nodes
}

moved {
  from = google_project_iam_member.gha_gke_viewer
  to   = module.gke.google_project_iam_member.gha_gke_viewer
}

moved {
  from = google_project_iam_member.gha_gke_developer
  to   = module.gke.google_project_iam_member.gha_gke_developer
}

moved {
  from = google_project_iam_member.gke_nodes_log_writer
  to   = module.gke.google_project_iam_member.gke_nodes_log_writer
}

moved {
  from = google_project_iam_member.gke_nodes_metric_writer
  to   = module.gke.google_project_iam_member.gke_nodes_metric_writer
}

moved {
  from = google_project_iam_member.gke_nodes_ar_reader
  to   = module.gke.google_project_iam_member.gke_nodes_ar_reader
}
