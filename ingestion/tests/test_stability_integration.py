from unittest.mock import MagicMock, patch

import pytest
import apache_beam as beam
from apache_beam.io.gcp.pubsub import PubsubMessage
from apache_beam.testing.util import assert_that, equal_to

from ingestion.pipeline.stability import WaitForFileStabilityDoFn
from ingestion.pipeline.parse import parse_notification, is_final_object
from ingestion.pipeline.map_fns import to_completeness_kv


@pytest.mark.integration
class TestStabilityIntegration:
    """Integration tests: pipeline with WaitForFileStabilityDoFn and mocked GCS."""

    def test_pipeline_non_success_events_do_not_emit(self):
        """Data-file events (not _SUCCESS) never yield from WaitForFileStabilityDoFn."""
        messages = [
            PubsubMessage(
                b"", {"bucketId": "b", "objectId": "stream/dt=2026-02-24/hour=1/part-0"}
            ),
        ]
        mock_client = MagicMock()
        mock_client.bucket.return_value = MagicMock()
        mock_client.list_blobs.return_value = []

        with patch(
            "ingestion.pipeline.stability.storage.Client", return_value=mock_client
        ):
            with beam.Pipeline() as p:
                out = (
                    p
                    | "Create" >> beam.Create(messages)
                    | "Parse" >> beam.Map(parse_notification)
                    | "FilterFinal" >> beam.Filter(is_final_object)
                    | "KeyForCompleteness" >> beam.Map(to_completeness_kv)
                    | "WaitForStable"
                    >> beam.ParDo(
                        WaitForFileStabilityDoFn(
                            project_id="test", poll_every_sec=30, stable_needed=2
                        )
                    )
                )
                assert_that(out, equal_to([]))

    def test_pipeline_with_mocked_gcs_and_success_event_runs(self):
        """Pipeline with _SUCCESS event and mocked GCS runs to completion."""
        messages = [
            PubsubMessage(
                b"",
                {
                    "bucketId": "test-bucket",
                    "objectId": "stream/dt=2026-02-24/hour=1/_SUCCESS",
                },
            ),
        ]
        mock_blob = lambda name, size: MagicMock(name=name, size=size)
        mock_client = MagicMock()
        mock_client.bucket.return_value = MagicMock()
        mock_client.list_blobs.return_value = [
            mock_blob("stream/dt=2026-02-24/hour=1/part-0", 100),
            mock_blob("stream/dt=2026-02-24/hour=1/part-1", 50),
        ]

        with patch(
            "ingestion.pipeline.stability.storage.Client", return_value=mock_client
        ):
            with beam.Pipeline() as p:
                _ = (
                    p
                    | "Create" >> beam.Create(messages)
                    | "Parse" >> beam.Map(parse_notification)
                    | "FilterFinal" >> beam.Filter(is_final_object)
                    | "KeyForCompleteness" >> beam.Map(to_completeness_kv)
                    | "WaitForStable"
                    >> beam.ParDo(
                        WaitForFileStabilityDoFn(
                            project_id="test-project",
                            poll_every_sec=1,
                            stable_needed=2,
                        )
                    )
                )
