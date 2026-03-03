variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "region" {
  type = string
}

variable "dataflow_image_version" {
  type = string
}

variable "ci_service_account_email" {
  type = string
}

variable "cloudbuild_runner_email" {
  type = string
}

variable "pubsub_subscription_name" {
  type = string
}

variable "datalake_bucket_name" {
  type    = string
  default = "wikistream-datalake"
}
