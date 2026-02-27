import pytest
import apache_beam as beam
from apache_beam.io.gcp.pubsub import PubsubMessage
from apache_beam.testing.util import assert_that, equal_to

from ingestion.pipeline.parse import parse_notification, is_final_object 

@pytest.mark.integration
class TestParseIntegration:

    def test_beam_pipeline_parse_and_filter_final_objects(self):
        messages = [
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/a/part-1"}),
            PubsubMessage(b"", {"bucketId": "b", "objectId": ".inprogress/stream/a/part-2"}),
            PubsubMessage(b"", {"bucketId": "b", "objectId": ".pending/stream/a/part-3"}),
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/a/part-4"}),
        ]

        expected_paths = [
            "gs://b/stream/a/part-1",
            "gs://b/stream/a/part-4",
        ]

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create(messages)
                | "Parse" >> beam.Map(parse_notification)
                | "FilterFinal" >> beam.Filter(is_final_object)
                | "ExtractPath" >> beam.Map(lambda e: e["file_path"])
            )

            assert_that(out, equal_to(expected_paths))


    def test_beam_pipeline_parse_missing_required_keys_fails(self):
        messages = [
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/a/part-1"}),
            PubsubMessage(b"", {"bucketId": "b"}),  # missing objectId
        ]

        with pytest.raises(Exception):
            with beam.Pipeline() as p:
                _ = (
                    p
                    | beam.Create(messages)
                    | beam.Map(parse_notification)
                )