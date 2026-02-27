"""
Unit and integration tests for ingestion.pipeline.deduplicate.
"""
import pytest
import apache_beam as beam
from apache_beam.io.gcp.pubsub import PubsubMessage
from apache_beam.testing.util import assert_that, equal_to

from ingestion.pipeline.deduplicate import key_for_dedup, DeduplicateDoFn
from ingestion.pipeline.map_fns import to_dedup_kv
from ingestion.pipeline.parse import parse_notification, is_final_object

@pytest.mark.unit
class TestDeduplicateIntegration:
    def test_integration_parse_filter_dedup_same_object_once(self):
        """Pipeline: parse notifications -> filter finals -> key -> dedup. Same object twice -> output once."""
        messages = [
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/dt=2026-02-24/hour=1/part-0000", "objectGeneration": "1"}),
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/dt=2026-02-24/hour=1/part-0000", "objectGeneration": "1"}),
        ]

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create(messages)
                | "Parse" >> beam.Map(parse_notification)
                | "FilterFinal" >> beam.Filter(is_final_object)
                | "KeyForDedup" >> beam.Map(to_dedup_kv)
                | "Deduplicate" >> beam.ParDo(DeduplicateDoFn())
                | "Paths" >> beam.Map(lambda e: e["file_path"])
            )
            assert_that(out, equal_to(["gs://b/stream/dt=2026-02-24/hour=1/part-0000"]))


    def test_integration_parse_filter_dedup_two_objects_both_kept(self):
        """Two different objects -> both appear in output after dedup."""
        messages = [
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/dt=2026-02-24/hour=1/part-0000"}),
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/dt=2026-02-24/hour=1/part-0001"}),
        ]

        expected_paths = [
            "gs://b/stream/dt=2026-02-24/hour=1/part-0000",
            "gs://b/stream/dt=2026-02-24/hour=1/part-0001",
        ]

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create(messages)
                | "Parse" >> beam.Map(parse_notification)
                | "FilterFinal" >> beam.Filter(is_final_object)
                | "KeyForDedup" >> beam.Map(to_dedup_kv)
                | "Deduplicate" >> beam.ParDo(DeduplicateDoFn())
                | "Paths" >> beam.Map(lambda e: e["file_path"])
            )
            assert_that(out, equal_to(expected_paths))


    def test_integration_parse_filter_dedup_inprogress_dropped_then_dedup(self):
        """Final objects are kept and deduped; .inprogress is filtered out before dedup."""
        messages = [
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/a/part-0"}),
            PubsubMessage(b"", {"bucketId": "b", "objectId": ".inprogress/stream/a/part-0"}),
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/a/part-0"}),
        ]

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create(messages)
                | "Parse" >> beam.Map(parse_notification)
                | "FilterFinal" >> beam.Filter(is_final_object)
                | "KeyForDedup" >> beam.Map(to_dedup_kv)
                | "Deduplicate" >> beam.ParDo(DeduplicateDoFn())
                | "Paths" >> beam.Map(lambda e: e["file_path"])
            )
            assert_that(out, equal_to(["gs://b/stream/a/part-0"]))