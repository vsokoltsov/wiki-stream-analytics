## Terraform GitHub Actions

This stack is configured to use a GCS backend via [backend.tf](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/terraform/backend.tf) and a dedicated GitHub Actions pipeline via [terraform.yml](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/.github/workflows/terraform.yml).

### One-time bootstrap

1. Create a dedicated GCS bucket for Terraform state.

```bash
gcloud storage buckets create gs://<TFSTATE_BUCKET> \
  --project=<GCP_PROJECT_ID> \
  --location=EU \
  --uniform-bucket-level-access
```

2. Enable object versioning on the state bucket.

```bash
gcloud storage buckets update gs://<TFSTATE_BUCKET> --versioning
```

3. Grant the GitHub Actions service account access to the state bucket.

```bash
gcloud storage buckets add-iam-policy-binding gs://<TFSTATE_BUCKET> \
 --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/storage.objectAdmin"
```

4. Bootstrap the GitHub Actions service account with the read permissions Terraform needs for `plan`.

```bash
gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/viewer"

gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/iam.securityReviewer"

gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/iam.serviceAccountViewer"

gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/iam.workloadIdentityPoolViewer"

gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/managedkafka.viewer"

gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/pubsub.viewer"

gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/secretmanager.viewer"

gcloud projects add-iam-policy-binding <GCP_PROJECT_ID> \
  --member="serviceAccount:<CI_SA_EMAIL>" \
  --role="roles/storage.admin"
```

5. Migrate the current local state into the remote backend.

```bash
terraform -chdir=infra/terraform init -migrate-state \
  -backend-config="bucket=<TFSTATE_BUCKET>" \
  -backend-config="prefix=<TFSTATE_PREFIX>"
```

### Required GitHub repository secrets

- `GCP_PROJECT_ID`
- `WIF_PROVIDER`
- `CI_SA_EMAIL`

### Required GitHub repository variables

- `TFSTATE_BUCKET`
- `TFSTATE_PREFIX`
- `TF_VAR_BUCKET_NAME`
- `GCP_REGION`
- `GCP_ZONE`

### Pipeline behavior

- Runs only when files under `infra/terraform/**` change
- Runs `terraform init`, `terraform fmt -check`, `terraform validate`, `terraform test`, and `terraform plan`
- Fails if `terraform plan` reports any changes

### Notes

- The native Terraform tests pull remote state into a local `terraform.tfstate` file before `terraform test`.
- The backend bucket must be created outside this stack. Do not try to manage the backend bucket from the same Terraform root that uses it as its backend.
- The CI service account must be bootstrapped once outside GitHub Actions, because the workflow is verification-only and cannot grant its own missing IAM permissions.
