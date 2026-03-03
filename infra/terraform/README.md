# Terraform Infrastructure

This directory contains the Terraform root module for the Wiki Stream Analytics infrastructure on Google Cloud.

The stack is split into business-oriented modules. The root layer is intentionally thin: it wires modules together, configures providers, exposes outputs, and defines the remote state backend.

## What This Stack Creates

At a high level, this Terraform stack provisions:

- project bootstrap services and APIs
- CI/CD infrastructure for GitHub Actions and Cloud Build
- network infrastructure
- GKE cluster infrastructure
- Kubernetes add-ons on top of GKE
- streaming infrastructure based on Managed Kafka
- data lake storage and Pub/Sub notifications
- analytics infrastructure in BigQuery and Dataflow support buckets

## Module Overview

### `bootstrap`

Purpose: enable all required Google Cloud APIs for the rest of the stack.

Typical contents:

- `google_project_service` resources

This module is upstream of almost everything else.

### `ci_cd`

Purpose: provide delivery and automation infrastructure for the repository.

Typical contents:

- Artifact Registry
- Cloud Build staging bucket
- GitHub Actions CI service account
- Cloud Build runner service account
- Workload Identity Pool and provider for GitHub OIDC
- IAM bindings required by CI

This module is also where the Terraform CI service account permissions are managed in code.

### `network`

Purpose: create the shared VPC layer used by runtime infrastructure.

Typical contents:

- VPC
- subnet
- router
- Cloud NAT

### `gke`

Purpose: provision the Google Kubernetes Engine cluster itself.

Typical contents:

- GKE cluster
- node pool
- node service account
- IAM for nodes and CI access to the cluster

This module contains only cluster infrastructure. Kubernetes resources that require a live cluster stay out of this module to avoid provider bootstrap cycles.

### `gke_addons`

Purpose: install Kubernetes-level infrastructure after the cluster exists.

Typical contents:

- application namespace
- `cert-manager`
- Flink Kubernetes Operator
- Secrets Store CSI integration
- public IP / firewall for Flink UI access
- cluster RBAC bindings needed after cluster creation

This module uses the root-configured `kubernetes`, `helm`, and `kubectl` providers.

### `streaming`

Purpose: provision stream transport and runtime identities.

Typical contents:

- Managed Kafka cluster
- Kafka topic
- producer and processing service accounts
- Kubernetes service accounts for workload identity
- streaming-related secrets
- IAM for Kafka and Secret Manager access

### `data_lake`

Purpose: create the raw storage landing zone and object notification pipeline.

Typical contents:

- GCS data lake bucket
- Pub/Sub topic and subscription
- GCS to Pub/Sub notification
- bucket secret for runtime consumers
- IAM for processing access

### `analytics`

Purpose: provision analytical storage and Dataflow support resources.

Typical contents:

- BigQuery datasets and tables
- Dataflow staging / temp / templates buckets
- Dataflow and dbt service accounts
- IAM for Dataflow, BigQuery, and CI integrations

## Root Files

The important root files are:

- [backend.tf](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/terraform/backend.tf): remote backend declaration
- [providers.tf](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/terraform/providers.tf): provider and provider-source configuration
- [variables.tf](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/terraform/variables.tf): root inputs
- [outputs.tf](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/terraform/outputs.tf): stack outputs
- one `*.tf` file per root module instantiation

## Prerequisites

You need:

- Terraform `>= 1.6.0`
- `gcloud`
- access to the target GCP project
- credentials with enough permissions to create and manage all resources

For local work, authenticate first:

```bash
gcloud auth application-default login
gcloud config set project <GCP_PROJECT_ID>
```

## Variables

The most important root variables are:

- `project_id`: target GCP project
- `bucket_name`: globally unique data lake bucket name
- `github_owner`: GitHub org/user for Workload Identity restriction
- `github_repo`: GitHub repo name for Workload Identity restriction
- `region`: main GCP region, default `europe-west3`
- `zone`: main GCP zone, default `europe-west3-a`
- `app_namespace`: Kubernetes namespace, default `wikistream`

You can provide variables via:

- `terraform.tfvars`
- CLI `-var`
- environment variables such as `TF_VAR_project_id`

Example:

```bash
export TF_VAR_project_id="my-project"
export TF_VAR_bucket_name="my-datalake-bucket"
export TF_VAR_github_owner="my-org"
export TF_VAR_github_repo="wiki-stream-analytics"
```

## Remote State

This stack uses a GCS backend:

```hcl
terraform {
  backend "gcs" {}
}
```

Backend settings are provided during `terraform init`, not hardcoded in the repository.

Example:

```bash
terraform -chdir=infra/terraform init \
  -backend-config="bucket=<TFSTATE_BUCKET>" \
  -backend-config="prefix=<TFSTATE_PREFIX>"
```

The backend bucket must already exist before `init`. It should not be created by this same Terraform root.

## Local Workflow

### 1. Initialize Terraform

```bash
terraform -chdir=infra/terraform init \
  -backend-config="bucket=<TFSTATE_BUCKET>" \
  -backend-config="prefix=<TFSTATE_PREFIX>"
```

### 2. Format and validate

```bash
terraform -chdir=infra/terraform fmt -recursive
terraform -chdir=infra/terraform validate
```

### 3. Run tests

```bash
terraform -chdir=infra/terraform test
```

### 4. Review the plan

```bash
terraform -chdir=infra/terraform plan
```

### 5. Apply changes

```bash
terraform -chdir=infra/terraform apply
```

## Tests

This stack uses native Terraform tests from `terraform test`.

Tests live under [tests](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/terraform/tests) and are split into two categories:

- config-contract tests: validate the Terraform source structure and key definitions
- state-contract tests: validate the current applied state shape and exported outputs

State-contract tests read:

- `terraform.tfstate` when it exists and is non-empty
- otherwise `terraform.tfstate.backup` as a local fallback snapshot

In CI, the workflow pulls remote state before running tests:

```bash
terraform state pull > terraform.tfstate
terraform test
```

## GitHub Actions Pipeline

The Terraform pipeline lives in:

- [terraform.yml](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/.github/workflows/terraform.yml)

Behavior:

- runs only when files under `infra/terraform/**` or the workflow file change
- authenticates to GCP using GitHub OIDC and Workload Identity
- runs `terraform init`
- runs `terraform fmt -check`
- runs `terraform validate`
- pulls remote state and runs `terraform test`
- runs `terraform plan -detailed-exitcode`
- fails if the plan is non-empty

The pipeline is verification-only. It does not apply infrastructure.

## One-Time CI Bootstrap

Before the GitHub Actions Terraform workflow can run successfully, the CI service account must already exist and have enough permissions to refresh the state during `plan`.

Useful references:

- [GITHUB_ACTIONS.md](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/terraform/GITHUB_ACTIONS.md)
- [bootstrap_terraform_ci_iam.sh](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/scripts/bootstrap_terraform_ci_iam.sh)

Example:

```bash
export GCP_PROJECT_ID="<project-id>"
export CI_SA_EMAIL="<ci-service-account-email>"

./scripts/bootstrap_terraform_ci_iam.sh
```

Important: because the workflow is verification-only, these bootstrap permissions must be granted once outside GitHub Actions.

## Useful Commands

Show outputs:

```bash
terraform -chdir=infra/terraform output
```

Get CI service account email:

```bash
terraform -chdir=infra/terraform output -raw ci_service_account_email
```

Inspect remote state:

```bash
terraform -chdir=infra/terraform state list
terraform -chdir=infra/terraform state show module.gke.google_container_cluster.gke
```

Pull remote state locally:

```bash
terraform -chdir=infra/terraform state pull > infra/terraform/terraform.tfstate
```

## Notes

- `bootstrap` should stay focused on project/API enablement only.
- shared provider configuration stays at the root, not inside child modules.
- `gke` and `gke_addons` are intentionally separate to avoid Terraform provider dependency cycles.
- the root module is the composition layer; module internals should stay inside `modules/*`.
