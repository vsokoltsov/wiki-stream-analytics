module "streaming" {
  source = "./modules/streaming"

  project_id    = var.project_id
  region        = var.region
  app_namespace = module.gke_addons.app_namespace
  subnetwork_id = module.network.subnetwork_id

  depends_on = [module.bootstrap]
}

moved {
  from = google_managed_kafka_cluster.kafka
  to   = module.streaming.google_managed_kafka_cluster.kafka
}

moved {
  from = google_managed_kafka_topic.recentchange_raw
  to   = module.streaming.google_managed_kafka_topic.recentchange_raw
}

moved {
  from = google_service_account.producer_sa
  to   = module.streaming.google_service_account.producer_sa
}

moved {
  from = google_service_account.processing_sa
  to   = module.streaming.google_service_account.processing_sa
}

moved {
  from = kubernetes_service_account_v1.processing
  to   = module.streaming.kubernetes_service_account_v1.processing
}

moved {
  from = kubernetes_service_account_v1.producer
  to   = module.streaming.kubernetes_service_account_v1.producer
}

moved {
  from = google_project_iam_member.producer_kafka
  to   = module.streaming.google_project_iam_member.producer_kafka
}

moved {
  from = google_project_iam_member.processing_kafka
  to   = module.streaming.google_project_iam_member.processing_kafka
}

moved {
  from = google_service_account_iam_member.producer_wi
  to   = module.streaming.google_service_account_iam_member.producer_wi
}

moved {
  from = google_service_account_iam_member.processing_wi
  to   = module.streaming.google_service_account_iam_member.processing_wi
}

moved {
  from = google_project_iam_member.producer_secret_accessor
  to   = module.streaming.google_project_iam_member.producer_secret_accessor
}

moved {
  from = google_project_iam_member.processing_secret_accessor
  to   = module.streaming.google_project_iam_member.processing_secret_accessor
}

moved {
  from = google_secret_manager_secret.wiki_user_agent
  to   = module.streaming.google_secret_manager_secret.wiki_user_agent
}

moved {
  from = google_secret_manager_secret_version.wiki_user_agent_v1
  to   = module.streaming.google_secret_manager_secret_version.wiki_user_agent_v1
}

moved {
  from = google_secret_manager_secret.kafka_bootstrap
  to   = module.streaming.google_secret_manager_secret.kafka_bootstrap
}

moved {
  from = google_secret_manager_secret.kafka_bootstrap_mtls
  to   = module.streaming.google_secret_manager_secret.kafka_bootstrap_mtls
}

moved {
  from = google_secret_manager_secret_version.kafka_bootstrap_v1
  to   = module.streaming.google_secret_manager_secret_version.kafka_bootstrap_v1
}

moved {
  from = google_secret_manager_secret_version.kafka_bootstrap_mtls_v1
  to   = module.streaming.google_secret_manager_secret_version.kafka_bootstrap_mtls_v1
}

moved {
  from = google_secret_manager_secret.kafka_sasl_username
  to   = module.streaming.google_secret_manager_secret.kafka_sasl_username
}

moved {
  from = google_secret_manager_secret_version.kafka_sasl_username_v1
  to   = module.streaming.google_secret_manager_secret_version.kafka_sasl_username_v1
}

moved {
  from = google_secret_manager_secret.kafka_sasl_username_processing
  to   = module.streaming.google_secret_manager_secret.kafka_sasl_username_processing
}

moved {
  from = google_secret_manager_secret_version.kafka_sasl_username_processing_v1
  to   = module.streaming.google_secret_manager_secret_version.kafka_sasl_username_processing_v1
}
