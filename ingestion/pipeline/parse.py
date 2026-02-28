from typing import Dict, Any
from apache_beam.io.gcp.pubsub import PubsubMessage


def parse_notification(m: PubsubMessage) -> Dict[str, Any]:
    attrs = m.attributes or {}
    bucket = attrs["bucketId"]
    obj = attrs["objectId"]
    gen = attrs.get("objectGeneration", "")
    prefix = obj.rsplit("/", 1)[0] + "/"

    return {
        "bucket": bucket,
        "object": obj,
        "generation": gen,
        "event_time": attrs.get("eventTime"),
        "event_type": attrs.get("eventType"),
        "file_path": f"gs://{bucket}/{obj}",
        "prefix": prefix,
        "attributes": dict(attrs),
    }


def is_final_object(e: dict) -> bool:
    obj = e["object"]
    return not (obj.startswith(".inprogress/") or obj.startswith(".pending/"))
