from typing import Dict
from dataclasses import dataclass
from pyflink.datastream.data_stream import DataStream
from pyflink.table import StreamTableEnvironment
from pyflink.table import Schema, DataTypes, TableDescriptor
from pyflink.table.table_result import TableResult
from pyflink.table.expressions import col, call_sql


@dataclass
class DatalakeStreamingPipeline:
    curated_stream: DataStream
    bucket_path: str
    t_env: StreamTableEnvironment
    descriptor_options: Dict[str, str]

    def build(self) -> TableResult:
        curated_table = self.t_env.from_data_stream(
            self.curated_stream,
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
            .build(),
        )

        self.t_env.create_temporary_view("curated_view", curated_table)

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
            .option("path", self.bucket_path)
            .format("parquet")
            # .option("partition.fields", "dt,hour")
        )
        for key, value in self.descriptor_options.items():
            sink_descriptor = sink_descriptor.option(key, value)

        sink_descriptor = sink_descriptor.build()

        self.t_env.create_table("gcs_sink", sink_descriptor)

        event_ts_expr = call_sql(
            "TO_TIMESTAMP_LTZ(CAST(event_ts_seconds * 1000 AS BIGINT), 3)"
        )

        return (
            self.t_env.from_path("curated_view")
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
