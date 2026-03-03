module "data_lake" {
  source = "./modules/data_lake"

  project_id                       = var.project_id
  location                         = var.location
  bucket_name                      = var.bucket_name
  name_prefix                      = var.name_prefix
  processing_service_account_email = module.streaming.processing_service_account_email

  depends_on = [module.bootstrap]
}

moved {
  from = google_storage_bucket.datalake
  to   = module.data_lake.google_storage_bucket.datalake
}

moved {
  from = google_storage_notification.to_pubsub
  to   = module.data_lake.google_storage_notification.to_pubsub
}

moved {
  from = google_pubsub_topic.datalake_objects
  to   = module.data_lake.google_pubsub_topic.datalake_objects
}

moved {
  from = google_pubsub_subscription.datalake_objects_sub
  to   = module.data_lake.google_pubsub_subscription.datalake_objects_sub
}

moved {
  from = data.google_storage_project_service_account.gcs
  to   = module.data_lake.data.google_storage_project_service_account.gcs
}

moved {
  from = google_pubsub_topic_iam_member.allow_gcs_publish
  to   = module.data_lake.google_pubsub_topic_iam_member.allow_gcs_publish
}

moved {
  from = google_storage_bucket_iam_member.processing_gcs_object_admin
  to   = module.data_lake.google_storage_bucket_iam_member.processing_gcs_object_admin
}

moved {
  from = module.streaming.google_secret_manager_secret.gcs_bucket
  to   = module.data_lake.google_secret_manager_secret.gcs_bucket
}

moved {
  from = module.streaming.google_secret_manager_secret_version.gcs_bucket_v1
  to   = module.data_lake.google_secret_manager_secret_version.gcs_bucket_v1
}
