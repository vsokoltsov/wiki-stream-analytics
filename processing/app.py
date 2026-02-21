import json
import os
from datetime import datetime, timezone
from pyflink.table.expressions import col, call_sql

from pyflink.common import Types, Row
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.connectors.kafka import KafkaSource, KafkaOffsetsInitializer
from pyflink.common.serialization import SimpleStringSchema
from pyflink.common.watermark_strategy import WatermarkStrategy

from pyflink.table import StreamTableEnvironment, Schema, DataTypes, TableDescriptor
from pyflink.table.expressions import col
from processing.settings import get_processing_settings


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
        ts_int,                          # event_ts_seconds
        str(wiki),                       # wiki
        str(typ),                        # type
        obj.get("user"),                 # user_name
        bool(obj.get("bot", False)),     # bot
        obj.get("title"),                # title
        obj.get("namespace"),            # namespace_id
        dt,                              # dt (partition)
        hour                             # hour (partition)
    )


def main():
    settings = get_processing_settings()
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(2)

    env.enable_checkpointing(60_000)
    bucket_path = f"gs://{settings.GCS_BUCKET}/stream"

    t_env = StreamTableEnvironment.create(env)

    # Kafka source
    source = (
        KafkaSource.builder()
        .set_bootstrap_servers(settings.KAFKA_BOOTSTRAP_SERVERS)
        .set_topics(settings.KAFKA_TOPIC)
        .set_group_id(settings.KAFKA_GROUP_ID)
        .set_starting_offsets(KafkaOffsetsInitializer.earliest())
        .set_value_only_deserializer(SimpleStringSchema())
        .build()
    )

    raw_stream = env.from_source(
        source,
        watermark_strategy=WatermarkStrategy.no_watermarks(),
        source_name="kafka-raw",
    )

    curated_stream = (
        raw_stream
        .map(
            parse_curated_row,
            output_type=Types.ROW([
                Types.INT(),      # event_ts_seconds
                Types.STRING(),   # wiki
                Types.STRING(),   # type
                Types.STRING(),   # user_name
                Types.BOOLEAN(),  # bot
                Types.STRING(),   # title
                Types.INT(),      # namespace_id
                Types.STRING(),   # dt
                Types.STRING(),   # hour
            ])
        )
        .filter(lambda r: r is not None)
    )

    # DataStream -> Table
    curated_table = t_env.from_data_stream(
        curated_stream,
        Schema.new_builder()
        .column_by_expression("event_ts_seconds", col("f0"))
        .column_by_expression("wiki", col("f1"))
        .column_by_expression("type", col("f2"))
        .column_by_expression("user_name", col("f3"))
        .column_by_expression("bot", col("f4"))
        .column_by_expression("title", col("f5"))
        .column_by_expression("namespace_id", col("f6"))
        .column_by_expression("dt", col("f7"))
        .column_by_expression("hour", col("f8"))
        .build()
    )

    t_env.create_temporary_view("curated_view", curated_table)
    
    # Sink table (filesystem -> parquet -> GCS)
    sink_descriptor = (
        TableDescriptor.for_connector("filesystem")
        .schema(
            Schema.new_builder()
            .column("event_ts", DataTypes.TIMESTAMP_LTZ(3))
            .column("wiki", DataTypes.STRING())
            .column("type", DataTypes.STRING())
            .column("user_name", DataTypes.STRING())
            .column("bot", DataTypes.BOOLEAN())
            .column("title", DataTypes.STRING())
            .column("namespace_id", DataTypes.INT())
            .column("dt", DataTypes.STRING())
            .column("hour", DataTypes.STRING())
            .build()
        )
        .partitioned_by("dt", "hour")
        .option("path", bucket_path)
        .format("parquet")
        # .option("partition.fields", "dt,hour")

        .option("sink.rolling-policy.file-size", "128MB")
        .option("sink.rolling-policy.rollover-interval", "5 min")
        .option("sink.rolling-policy.check-interval", "1 min")

        .option("sink.partition-commit.trigger", "process-time")
        .option("sink.partition-commit.delay", "1 min")
        .option("sink.partition-commit.policy.kind", "success-file")
        .build()
    )

    event_ts_expr = call_sql(
        "TO_TIMESTAMP_LTZ(CAST(event_ts_seconds * 1000 AS BIGINT), 3)"
    )

    t_env.create_table("gcs_sink", sink_descriptor)

    table_result = (
        t_env.from_path("curated_view")
        .select(
            event_ts_expr.alias("event_ts"),
            col("wiki"),
            col("type"),
            col("user_name"),
            col("bot"),
            col("title"),
            col("namespace_id"),
            col("dt"),
            col("hour"),
        )
        .execute_insert("gcs_sink")
    )

    table_result.wait()


if __name__ == "__main__":
    main()