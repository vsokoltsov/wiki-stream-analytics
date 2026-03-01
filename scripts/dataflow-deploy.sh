export PROJECT_ID="wiki-stream-analytics"
export REGION="europe-west1"
export AR_REPO="wiki-stream-analytics"
export IMAGE_NAME="wiki-ingestion"
export TAG="latest"
export TEMPLATE_BUCKET="wiki-stream-analytics-dataflow-templates"
export STAGING_BUCKET="wiki-stream-analytics-dataflow-staging"
export TEMP_BUCKET="wiki-stream-analytics-dataflow-temp"
export TEMPLATE_PATH="gs://${TEMPLATE_BUCKET}/templates/${IMAGE_NAME}_flex.json"
export IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --config ingestion/cloudbuild.yaml --substitutions _TAG="$(date +%Y%m%d-%H%M%S)" .

gcloud dataflow flex-template run "wikistream-ingestion-$(date +%Y%m%d-%H%M%S)" \
  --project "wiki-stream-analytics" \
  --region "europe-west2" \
  --num-workers 2 \
  --max-workers 4 \
  --worker-machine-type "e2-standard-2" \
  --template-file-gcs-location "gs://wiki-stream-analytics-dataflow-templates/templates/wikistream_ingestion_flex.json" \
  --additional-pipeline-options="sdk_container_image=europe-west3-docker.pkg.dev/wiki-stream-analytics/wiki-stream-analytics/wiki-ingestion:20260227-205659" \
  --parameters project="wiki-stream-analytics" \
  --parameters subscription="projects/wiki-stream-analytics/subscriptions/wikistream-datalake-objects-sub" \
  --parameters table_id="wiki-stream-analytics.wikistream_raw.recentchanges" \
  --parameters temp_location="gs://wiki-stream-analytics-dataflow-temp/tmp" \
  --parameters staging_location="gs://wiki-stream-analytics-dataflow-staging/staging" \
  --parameters sdk_container_image="europe-west3-docker.pkg.dev/wiki-stream-analytics/wiki-stream-analytics/wiki-ingestion:20260227-205659"