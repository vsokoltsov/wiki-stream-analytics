import pytest
import apache_beam as beam
from apache_beam.io.gcp.pubsub import PubsubMessage
from apache_beam.testing.util import assert_that, equal_to

from ingestion.pipeline.parse import parse_notification, is_final_object 

def test_parse_notification_happy_path():
    attrs = {
        "bucketId": "wikistream-datalake",
        "objectId": "stream/dt=2026-02-24/hour=21/part-0001",
        "objectGeneration": "12345",
        "eventTime": "2026-02-24T21:00:00Z",
        "eventType": "OBJECT_FINALIZE",
    }
    m = PubsubMessage(data=b"", attributes=attrs)

    out = parse_notification(m)

    assert out["bucket"] == "wikistream-datalake"
    assert out["object"] == "stream/dt=2026-02-24/hour=21/part-0001"
    assert out["generation"] == "12345"
    assert out["event_time"] == "2026-02-24T21:00:00Z"
    assert out["event_type"] == "OBJECT_FINALIZE"
    assert out["file_path"] == "gs://wikistream-datalake/stream/dt=2026-02-24/hour=21/part-0001"
    assert out["prefix"] == "stream/dt=2026-02-24/hour=21/"
    assert out["attributes"] == attrs


def test_parse_notification_missing_optional_fields_generation_and_event_fields():
    attrs = {
        "bucketId": "wikistream-datalake",
        "objectId": "stream/dt=2026-02-24/hour=21/part-0001",
        # objectGeneration absent
        # eventTime/eventType absent
    }
    m = PubsubMessage(data=b"ignored", attributes=attrs)

    out = parse_notification(m)

    assert out["generation"] == ""
    assert out["event_time"] is None
    assert out["event_type"] is None
    assert out["prefix"] == "stream/dt=2026-02-24/hour=21/"


@pytest.mark.parametrize(
    "attrs, missing_key",
    [
        ({"objectId": "x/y"}, "bucketId"),
        ({"bucketId": "b"}, "objectId"),
        ({}, "bucketId"),
    ],
)
def test_parse_notification_raises_keyerror_when_required_missing(attrs, missing_key):
    m = PubsubMessage(data=b"", attributes=attrs)
    with pytest.raises(KeyError):
        parse_notification(m)


def test_parse_notification_attributes_none_raises_keyerror():
    # m.attributes is None -> attrs = {} -> KeyError for required keys
    m = PubsubMessage(data=b"", attributes=None)
    with pytest.raises(KeyError):
        parse_notification(m)


def test_parse_notification_prefix_with_no_slash_in_objectid_is_root_prefix():
    attrs = {"bucketId": "b", "objectId": "file.parquet"}
    m = PubsubMessage(data=b"", attributes=attrs)

    out = parse_notification(m)
    assert out["prefix"] == "file.parquet/"

@pytest.mark.parametrize(
    "obj, expected",
    [
        ("stream/dt=2026-02-24/hour=21/part-0001", True),
        (".inprogress/stream/x", False),
        (".pending/stream/x", False),
        ("something/.inprogress/x", True),
        ("something/.pending/x", True),
    ],
)
def test_is_final_object(obj, expected):
    assert is_final_object({"object": obj}) is expected


def test_is_final_object_missing_object_key_raises():
    with pytest.raises(KeyError):
        is_final_object({})
