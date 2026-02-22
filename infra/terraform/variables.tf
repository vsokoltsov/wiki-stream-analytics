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

# app namespace
variable "app_namespace" {
  type    = string
  default = "wikistream"
}

# Operator versions (Operator 1.14.0 is current as of Feb 2026)  [oai_citation:3‡flink.apache.org](https://flink.apache.org/2026/02/15/apache-flink-kubernetes-operator-1.14.0-release-announcement/?utm_source=chatgpt.com)
variable "flink_operator_version" {
  type    = string
  default = "1.14.0"
}

# cert-manager chart
variable "cert_manager_version" {
  type    = string
  default = "v1.18.2"
}

# UI exposure
variable "enable_ingress" {
  type    = bool
  default = false
}

variable "ingress_host" {
  type        = string
  description = "DNS host for Flink UI ingress"
  default     = "flink-ui.example.com"
}