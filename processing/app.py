import json
import os
from datetime import datetime, timezone

from pyflink.common import Types, Row
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.connectors.kafka import KafkaSource, KafkaOffsetsInitializer
from pyflink.common.serialization import SimpleStringSchema
from pyflink.common.watermark_strategy import WatermarkStrategy

from pyflink.table import StreamTableEnvironment
from processing.settings import get_processing_settings
from processing.pipeline import DatalakeStreamingPipeline


def _dt_hour_from_ts_seconds(ts_seconds: int) -> tuple[str, str]:
    dt = datetime.fromtimestamp(ts_seconds, tz=timezone.utc)
    return dt.strftime("%Y-%m-%d"), dt.strftime("%H")


def parse_curated_row(raw: str):
    try:
        obj = json.loads(raw)
    except Exception:
        return None

    ts = obj.get("timestamp")
    wiki = obj.get("wiki")
    typ = obj.get("type")
    if ts is None or wiki is None or typ is None:
        return None

    try:
        ts_int = int(ts)
    except Exception:
        return None

    dt, hour = _dt_hour_from_ts_seconds(ts_int)

    return Row(
        ts_int,  # event_ts_seconds
        str(wiki),  # wiki
        str(typ),  # type
        obj.get("user"),  # user_name
        bool(obj.get("bot", False)),  # bot
        obj.get("title"),  # title
        obj.get("namespace"),  # namespace_id
        dt,  # dt (partition)
        hour,  # hour (partition)
    )


def build_kafka_source(settings) -> KafkaSource:
    mode = (
        getattr(settings, "KAFKA_MODE", None) or os.getenv("KAFKA_MODE", "PLAINTEXT")
    ).upper()

    builder = (
        KafkaSource.builder()
        .set_bootstrap_servers(settings.KAFKA_BOOTSTRAP_SERVERS)
        .set_topics(settings.KAFKA_TOPIC)
        .set_group_id(settings.KAFKA_GROUP_ID)
        .set_starting_offsets(KafkaOffsetsInitializer.earliest())
        .set_value_only_deserializer(SimpleStringSchema())
    )

    if mode == "PLAINTEXT":
        return builder.build()

    if mode == "GCP_OAUTH":
        # Java Kafka client properties
        props = {
            "security.protocol": "SASL_SSL",
            "sasl.mechanism": "OAUTHBEARER",
            "sasl.jaas.config": "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required;",
            "sasl.login.callback.handler.class": "com.google.cloud.hosted.kafka.auth.GcpLoginCallbackHandler",
            "request.timeout.ms": "30000",
            "default.api.timeout.ms": "30000",
            "retries": "10",
            "retry.backoff.ms": "1000",
        }

        return builder.set_properties(props).build()

    raise ValueError(f"Unknown KAFKA_MODE={mode}. Use PLAINTEXT or GCP_OAUTH.")


def main():
    settings = get_processing_settings()
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(2)

    env.enable_checkpointing(60_000)
    bucket_path = f"gs://{settings.GCS_BUCKET}/stream"

    t_env = StreamTableEnvironment.create(env)

    # Kafka source
    source = build_kafka_source(settings=settings)

    raw_stream = env.from_source(
        source,
        watermark_strategy=WatermarkStrategy.no_watermarks(),
        source_name="kafka-raw",
    )

    curated_stream = raw_stream.map(
        parse_curated_row,
        output_type=Types.ROW(
            [
                Types.INT(),  # event_ts_seconds
                Types.STRING(),  # wiki
                Types.STRING(),  # type
                Types.STRING(),  # user_name
                Types.BOOLEAN(),  # bot
                Types.STRING(),  # title
                Types.INT(),  # namespace_id
                Types.STRING(),  # dt
                Types.STRING(),  # hour
            ]
        ),
    ).filter(lambda r: r is not None)
    descriptor_options = {
        "sink.rolling-policy.file-size": "128MB",
        "sink.rolling-policy.rollover-interval": "5 min",
        "sink.partition-commit.trigger": "process-time",
        "sink.partition-commit.delay": "1 min",
        "sink.partition-commit.policy.kind": "success-file",
    }

    pipeline = DatalakeStreamingPipeline(
        curated_stream=curated_stream,
        t_env=t_env,
        bucket_path=bucket_path,
        descriptor_options=descriptor_options,
    )

    table_result = pipeline.build()

    table_result.wait()


if __name__ == "__main__":
    main()
