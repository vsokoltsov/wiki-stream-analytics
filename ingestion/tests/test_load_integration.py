from unittest.mock import MagicMock, patch

import pytest
import apache_beam as beam
from apache_beam.testing.util import assert_that, equal_to
from google.api_core.exceptions import BadRequest

from ingestion.pipeline.load import LoadFolderToBQDoFn

@pytest.mark.integration
class TestLoadIntegration:
    """Integration/functional tests: LoadFolderToBQDoFn in a pipeline with mocked BigQuery."""

    def test_pipeline_with_valid_folder_uri_emits_one_loaded_record(self):
        mock_job = MagicMock()
        mock_job.output_rows = 5
        mock_client = MagicMock()
        mock_client.load_table_from_uri.return_value = mock_job

        with patch("ingestion.pipeline.load.bigquery.Client", return_value=mock_client):
            with beam.Pipeline() as p:
                out = (
                    p
                    | "Create"
                    >> beam.Create(
                        [
                            {
                                "folder_uri": "gs://test-bucket/stream/dt=2026-02-24/hour=1/*",
                                "bq_table": "proj.ds.tbl",
                                "dt": "2026-02-24",
                                "hour": 1,
                            }
                        ]
                    )
                    | "LoadToBQ" >> beam.ParDo(LoadFolderToBQDoFn(project_id="test-project"))
                )
                result = out | "ExtractLoadedUri" >> beam.Map(lambda x: x.get("loaded_uri"))
                assert_that(result, equal_to(["gs://test-bucket/stream/dt=2026-02-24/hour=1/*"]))

    def test_pipeline_with_missing_folder_uri_emits_nothing(self):
        mock_client = MagicMock()
        with patch("ingestion.pipeline.load.bigquery.Client", return_value=mock_client):
            with beam.Pipeline() as p:
                out = (
                    p
                    | "Create"
                    >> beam.Create(
                        [
                            {
                                "bucket": "b",
                                "prefix": "p/",
                                "bq_table": "p.d.t",
                            }
                        ]
                    )
                    | "LoadToBQ" >> beam.ParDo(LoadFolderToBQDoFn(project_id="test-project"))
                )
                count = out | "Count" >> beam.combiners.Count.Globally()
                assert_that(count, equal_to([0]))

    def test_pipeline_with_bad_request_emits_failed_record(self):
        mock_job = MagicMock()
        mock_job.result.side_effect = BadRequest("Table not found")
        mock_client = MagicMock()
        mock_client.load_table_from_uri.return_value = mock_job

        with patch("ingestion.pipeline.load.bigquery.Client", return_value=mock_client):
            with beam.Pipeline() as p:
                out = (
                    p
                    | "Create"
                    >> beam.Create(
                        [
                            {
                                "folder_uri": "gs://b/p*",
                                "bq_table": "p.d.t",
                            }
                        ]
                    )
                    | "LoadToBQ" >> beam.ParDo(LoadFolderToBQDoFn(project_id="test"))
                )
                failed = out | "FailedOnly" >> beam.Filter(lambda x: "failed_uri" in x)
                assert_that(
                    failed,
                    equal_to([{"failed_uri": "gs://b/p*", "error": "400 Table not found", "table": "p.d.t"}]),
                )