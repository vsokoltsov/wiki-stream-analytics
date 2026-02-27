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
class TestDeduplicateUnit:
    def test_key_for_dedup_includes_bucket_object_and_generation(self):
        e = {
            "bucket": "my-bucket",
            "object": "stream/dt=2026-02-24/hour=1/part-0000",
            "generation": "12345",
        }
        assert key_for_dedup(e) == "my-bucket|stream/dt=2026-02-24/hour=1/part-0000|12345"


    def test_key_for_dedup_missing_generation_uses_empty_string(self):
        e = {"bucket": "b", "object": "path/to/obj"}
        assert key_for_dedup(e) == "b|path/to/obj|"


    def test_key_for_dedup_different_objects_different_keys(self):
        e1 = {"bucket": "b", "object": "path/a", "generation": "1"}
        e2 = {"bucket": "b", "object": "path/b", "generation": "1"}
        assert key_for_dedup(e1) != key_for_dedup(e2)


    def test_key_for_dedup_same_object_same_generation_same_key(self):
        e1 = {"bucket": "b", "object": "path/a", "generation": "1"}
        e2 = {"bucket": "b", "object": "path/a", "generation": "1"}
        assert key_for_dedup(e1) == key_for_dedup(e2)


    def test_key_for_dedup_same_object_different_generation_different_key(self):
        e1 = {"bucket": "b", "object": "path/a", "generation": "1"}
        e2 = {"bucket": "b", "object": "path/a", "generation": "2"}
        assert key_for_dedup(e1) != key_for_dedup(e2)


    @pytest.mark.parametrize("missing", ["bucket", "object"])
    def test_key_for_dedup_raises_keyerror_when_required_missing(self, missing):
        e = {"bucket": "b", "object": "path"}
        del e[missing]
        with pytest.raises(KeyError):
            key_for_dedup(e)


    # ---- Unit: DeduplicateDoFn (via pipeline) ----

    def test_deduplicate_dofn_first_occurrence_yields_event(self):
        """First time a key is seen, the event is yielded."""
        key = "b|path/to/obj|1"
        event = {"bucket": "b", "object": "path/to/obj", "generation": "1"}

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create([(key, event)])
                | "Dedup" >> beam.ParDo(DeduplicateDoFn())
            )
            assert_that(out, equal_to([event]))


    def test_deduplicate_dofn_duplicate_key_yields_only_once(self):
        """Two elements with the same key yield only the first."""
        key = "bucket|stream/part-0|gen1"
        event = {"bucket": "bucket", "object": "stream/part-0", "generation": "gen1"}

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create([(key, event), (key, {**event, "extra": "dup"})])
                | "Dedup" >> beam.ParDo(DeduplicateDoFn())
            )
            assert_that(out, equal_to([event]))


    def test_deduplicate_dofn_different_keys_both_yielded(self):
        """Different keys each yield their event."""
        k1, e1 = "b|path/a|", {"bucket": "b", "object": "path/a"}
        k2, e2 = "b|path/b|", {"bucket": "b", "object": "path/b"}

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create([(k1, e1), (k2, e2)])
                | "Dedup" >> beam.ParDo(DeduplicateDoFn())
            )
            assert_that(out, equal_to([e1, e2]))


    def test_deduplicate_dofn_three_events_two_keys_yields_two(self):
        """Two unique keys, one duplicate: output has two elements."""
        k1, e1 = "b|a|1", {"bucket": "b", "object": "a", "generation": "1"}
        k2, e2 = "b|b|2", {"bucket": "b", "object": "b", "generation": "2"}

        with beam.Pipeline() as p:
            out = (
                p
                | "Create" >> beam.Create([(k1, e1), (k2, e2), (k1, {**e1, "replay": True})])
                | "Dedup" >> beam.ParDo(DeduplicateDoFn())
            )
            assert_that(out, equal_to([e1, e2]))