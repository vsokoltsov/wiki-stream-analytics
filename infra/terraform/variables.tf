variable "project_id" {
  description = "GCP project id where all resources will be created."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming and labeling (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "GCP region for regional resources (e.g., europe-west3)."
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "GCP zone for zonal resources (e.g., europe-west3-a)."
  type        = string
  default     = "europe-west3-a"
}

variable "github_owner" { 
  type = string 
}
variable "github_repo"  { 
  type = string 
}

variable "wif_pool_id"     { 
  type = string
  default = "github" 
}
variable "wif_provider_id" { 
  type = string
  default = "github-provider" 
}

variable "ci_sa_account_id" { 
  type = string
  default = "gha-ci" 
}

variable "enable_k8s" {
  type    = bool
  default = true
}

variable "location" {
  type        = string
  description = "Bucket location"
  default     = "EU"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique GCS bucket name"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "wikistream"
}