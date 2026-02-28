import pytest
import apache_beam as beam
from apache_beam.io.gcp.pubsub import PubsubMessage
from unittest.mock import MagicMock, patch

from ingestion.pipeline.definition import create_ingestion_pipeline


@pytest.mark.integration
class TestDefinitionIntegration:
    """Integration tests: full DAG with mocked I/O (Pub/Sub, GCS stability, BQ)."""

    def test_pipeline_e2e_mocked_sources_and_sinks(self):
        """Run create_ingestion_pipeline with ReadFromPubSub replaced by Create, mock stability and BQ."""
        messages = [
            PubsubMessage(
                b"",
                {
                    "bucketId": "b",
                    "objectId": "stream/dt=2026-02-24/hour=1/part-0000",
                    "objectGeneration": "1",
                },
            ),
        ]
        args = {
            "subscription": "projects/p/subs/s",
            "project": "test-project",
            "table_id": "test-project.dataset.raw",
        }

        class PassThroughStabilityDoFn(beam.DoFn):
            def process(self, kv):  # type: ignore[override]
                key, event = kv
                event = dict(event)
                event["folder_uri"] = f"gs://{event['bucket']}/{event['prefix']}*"
                yield event

        mock_job = MagicMock()
        mock_job.output_rows = 0
        mock_client = MagicMock()
        mock_client.load_table_from_uri.return_value = mock_job

        with (
            patch(
                "ingestion.pipeline.definition.ReadFromPubSub",
                return_value=beam.Create(messages),
            ),
            patch(
                "ingestion.pipeline.definition.WaitForFileStabilityDoFn",
                side_effect=lambda *args, **kwargs: PassThroughStabilityDoFn(),
            ),
            patch("ingestion.pipeline.load.bigquery.Client", return_value=mock_client),
        ):
            with beam.Pipeline() as p:
                create_ingestion_pipeline(p, args)
                result = p.run()
            result.wait_until_finish()

    def test_pipeline_e2e_bq_client_called_mocked(self):
        """Run DAG with Create as source, mock stability and BQ, assert BQ load was called."""
        messages = [
            PubsubMessage(
                b"",
                {
                    "bucketId": "b",
                    "objectId": "stream/dt=2026-02-24/hour=2/part-0001",
                    "objectGeneration": "2",
                },
            ),
        ]
        args = {
            "subscription": "projects/p/subs/s",
            "project": "test-project",
            "table_id": "p.ds.raw",
        }

        class PassThroughStabilityDoFn(beam.DoFn):
            def process(self, kv):  # type: ignore[override]
                key, event = kv
                event = dict(event)
                event["folder_uri"] = f"gs://{event['bucket']}/{event['prefix']}*"
                yield event

        mock_job = MagicMock()
        mock_job.output_rows = 10
        mock_client = MagicMock()
        mock_client.load_table_from_uri.return_value = mock_job

        with (
            patch(
                "ingestion.pipeline.definition.ReadFromPubSub",
                return_value=beam.Create(messages),
            ),
            patch(
                "ingestion.pipeline.definition.WaitForFileStabilityDoFn",
                side_effect=lambda *args, **kwargs: PassThroughStabilityDoFn(),
            ),
            patch("ingestion.pipeline.load.bigquery.Client", return_value=mock_client),
        ):
            with beam.Pipeline() as p:
                create_ingestion_pipeline(p, args)
                result = p.run()
            result.wait_until_finish()

        mock_client.load_table_from_uri.assert_called()
        assert any(
            "gs://b/stream/dt=2026-02-24/hour=2/*" in str(c)
            for c in mock_client.load_table_from_uri.call_args_list
        )
