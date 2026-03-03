#!/usr/bin/env bash

set -euo pipefail

: "${GCP_PROJECT_ID:?GCP_PROJECT_ID is required}"
: "${CI_SA_EMAIL:?CI_SA_EMAIL is required}"

member="serviceAccount:${CI_SA_EMAIL}"
roles=(
  "roles/viewer"
  "roles/iam.securityReviewer"
  "roles/iam.serviceAccountViewer"
  "roles/iam.workloadIdentityPoolViewer"
  "roles/managedkafka.viewer"
  "roles/pubsub.viewer"
  "roles/secretmanager.viewer"
  "roles/storage.admin"
)

for role in "${roles[@]}"; do
  echo "Granting ${role} to ${member} in project ${GCP_PROJECT_ID}"
  gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member="${member}" \
    --role="${role}"
done
