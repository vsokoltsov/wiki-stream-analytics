import pytest
import apache_beam as beam
from apache_beam.io.gcp.pubsub import PubsubMessage
from apache_beam.testing.util import assert_that, equal_to

from ingestion.pipeline.routing import add_partition_info
from ingestion.pipeline.parse import parse_notification, is_final_object
from ingestion.pipeline.deduplicate import DeduplicateDoFn
from ingestion.pipeline.map_fns import to_dedup_kv, to_completeness_kv

@pytest.mark.integration
class TestRoutingIntegration:
    def test_integration_parse_to_routing_adds_partition_and_table(self):
        """Pipeline up to add_partition_info: parsed events get dt, hour, bq_table from prefix."""
        messages = [
            PubsubMessage(b"", {"bucketId": "b", "objectId": "stream/dt=2026-02-24/hour=21/part-0000"}),
        ]
        table_id = "wiki-stream-analytics.wikistream_raw.recentchanges"

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create(messages)
                | "Parse" >> beam.Map(parse_notification)
                | "FilterFinal" >> beam.Filter(is_final_object)
                | "KeyForDedup" >> beam.Map(to_dedup_kv)
                | "Deduplicate" >> beam.ParDo(DeduplicateDoFn())
                | "AddPartitionInfo" >> beam.Map(add_partition_info, table_id=table_id)
                | "Extract" >> beam.Map(lambda e: (e["dt"], e["hour"], e["bq_table"]))
            )
            assert_that(out, equal_to([("2026-02-24", 21, table_id)]))


    def test_integration_routing_preserves_other_fields(self):
        """add_partition_info in pipeline preserves bucket, prefix, file_path and adds dt, hour, bq_table."""
        messages = [
            PubsubMessage(b"", {"bucketId": "my-bucket", "objectId": "stream/dt=2025-01-10/hour=5/part-1"}),
        ]

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create(messages)
                | "Parse" >> beam.Map(parse_notification)
                | "FilterFinal" >> beam.Filter(is_final_object)
                | "KeyForDedup" >> beam.Map(to_dedup_kv)
                | "Deduplicate" >> beam.ParDo(DeduplicateDoFn())
                | "AddPartitionInfo" >> beam.Map(add_partition_info, table_id="p.d.t")
                | "Extract" >> beam.Map(lambda e: (e["bucket"], e["prefix"], e["file_path"], e["dt"], e["hour"], e["bq_table"]))
            )
            assert_that(
                out,
                equal_to([
                    (
                        "my-bucket",
                        "stream/dt=2025-01-10/hour=5/",
                        "gs://my-bucket/stream/dt=2025-01-10/hour=5/part-1",
                        "2025-01-10",
                        5,
                        "p.d.t",
                    )
                ]),
            )