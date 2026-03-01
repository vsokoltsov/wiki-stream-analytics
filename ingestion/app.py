import apache_beam as beam
from typing import Dict, Any
from ingestion.settings import get_ingestion_settings
from ingestion.pipeline.definition import create_ingestion_pipeline
from apache_beam.options.pipeline_options import PipelineOptions

ALLOWED_PREFIX = "gs://wikistream-datalake/stream_fixed_us/"


def is_allowed(e):
    uri = e.get("folder_uri") or e.get("file_path")
    return uri and uri.startswith(ALLOWED_PREFIX)


if __name__ == "__main__":
    settings = get_ingestion_settings()
    table_id = f"{settings.PROJECT_ID}.{settings.BQ_DATASET}.{settings.BQ_TABLE}"
    options = PipelineOptions(streaming=True)
    args: Dict[str, Any] = {
        "subscription": settings.PUBSUB_SUBSCRIPTION,
        "project": settings.PROJECT_ID,
        "table_id": table_id,
    }
    with beam.Pipeline(options=options) as p:
        create_ingestion_pipeline(p=p, args=args)
