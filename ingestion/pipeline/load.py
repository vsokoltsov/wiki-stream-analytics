from typing import Dict, Any
import apache_beam as beam
from google.cloud import bigquery
from google.api_core.exceptions import BadRequest
import logging

logger = logging.getLogger(__name__)


class LoadFolderToBQDoFn(beam.DoFn):
    def __init__(self, project_id: str):
        self.project_id = project_id
        self._bq = None

    def setup(self):
        self._bq = bigquery.Client(project=self.project_id)

    def process(self, e: Dict[str, Any]):  # type: ignore[override]
        if not self._bq:
            raise ValueError("BigQuery client was not initialized!")

        folder_uri = e.get("folder_uri")
        if not folder_uri or not folder_uri.endswith("*"):
            logger.warning(
                "Skipping load: missing folder_uri",
                extra={
                    "bucket": e.get("bucket"),
                    "prefix": e.get("prefix"),
                    "file_path": e.get("file_path"),
                    "dt": e.get("dt"),
                    "hour": e.get("hour"),
                    "bq_table": e.get("bq_table"),
                },
            )
            return

        uri = e["folder_uri"]
        table_id = e["bq_table"]

        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.PARQUET,
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
            schema=[
                bigquery.SchemaField("event_ts", "TIMESTAMP", mode="REQUIRED"),
                bigquery.SchemaField("wiki", "STRING", mode="NULLABLE"),
                bigquery.SchemaField("type", "STRING", mode="NULLABLE"),
                bigquery.SchemaField("user_name", "STRING", mode="NULLABLE"),
                bigquery.SchemaField("bot", "BOOLEAN", mode="NULLABLE"),
                bigquery.SchemaField("title", "STRING", mode="NULLABLE"),
                bigquery.SchemaField("namespace_id", "INTEGER", mode="NULLABLE"),
            ],
        )
        try:
            job = self._bq.load_table_from_uri(uri, table_id, job_config=job_config)
            job.result()
            yield {
                "loaded_uri": uri,
                "table": table_id,
                "output_rows": job.output_rows,
                "dt": e.get("dt"),
                "hour": e.get("hour"),
            }
        except BadRequest as err:
            yield {"failed_uri": uri, "error": str(err), "table": table_id}
            return
