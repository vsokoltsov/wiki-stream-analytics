import json
import os
import time
from pathlib import Path

import pytest
import pandas as pd

from pyflink.common import Types
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment
from pyflink.common.watermark_strategy import WatermarkStrategy

from processing.app import parse_curated_row
from processing.pipeline import DatalakeStreamingPipeline


@pytest.mark.integration
def test_pipeline_writes_parquet_to_local_fs(tmp_path: Path):
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(1)
    env.enable_checkpointing(1000)

    root_folder = Path(__file__).resolve().parents[1]
    parquet_jar = os.path.join(root_folder, "jars", "flink-sql-parquet-2.0.1.jar")
    kafka_connector_jar = os.path.join(
        root_folder, "jars", "flink-connector-kafka-4.0.1-2.0.jar"
    )
    hadoop_api = os.path.join(root_folder, "jars", "hadoop-client-api-3.3.6.jar")
    hadoop_auth = os.path.join(root_folder, "jars", "hadoop-auth-3.3.6.jar")
    hadoop_runtime = os.path.join(
        root_folder, "jars", "hadoop-client-runtime-3.3.6.jar"
    )
    kafka_clients = os.path.join(root_folder, "jars", "kafka-clients-3.9.1.jar")
    env.add_jars(
        f"file://{parquet_jar}",
        f"file://{kafka_connector_jar}",
        f"file://{hadoop_api}",
        f"file://{hadoop_auth}",
        f"file://{hadoop_runtime}",
        f"file://{kafka_clients}",
    )

    t_env = StreamTableEnvironment.create(env)

    raw_events = [
        json.dumps(
            {
                "timestamp": 0,
                "wiki": "enwiki",
                "type": "edit",
                "user": "u1",
                "bot": False,
                "title": "t1",
                "namespace": 0,
            }
        ),
        json.dumps(
            {
                "timestamp": 1,
                "wiki": "dewiki",
                "type": "new",
                "user": "u2",
                "bot": True,
                "title": "t2",
                "namespace": 1,
            }
        ),
    ]

    raw_stream = env.from_collection(
        raw_events, type_info=Types.STRING()
    ).assign_timestamps_and_watermarks(WatermarkStrategy.no_watermarks())

    curated_stream = raw_stream.map(
        parse_curated_row,
        output_type=Types.ROW(
            [
                Types.INT(),
                Types.STRING(),
                Types.STRING(),
                Types.STRING(),
                Types.BOOLEAN(),
                Types.STRING(),
                Types.INT(),
                Types.STRING(),
                Types.STRING(),
            ]
        ),
    ).filter(lambda r: r is not None)

    sink_path = (tmp_path / "stream").as_uri()  # file:///...
    descriptor_options = {
        "sink.rolling-policy.file-size": "1 KB",
        "sink.rolling-policy.rollover-interval": "1 s",
        "sink.rolling-policy.inactivity-interval": "1 s",
        "sink.rolling-policy.check-interval": "1 s",
        "sink.partition-commit.trigger": "process-time",
        "sink.partition-commit.delay": "0 s",
        "sink.partition-commit.policy.kind": "success-file",
    }
    pipeline = DatalakeStreamingPipeline(
        curated_stream=curated_stream,
        bucket_path=sink_path,
        t_env=t_env,
        descriptor_options=descriptor_options,
    )
    table = pipeline.build()
    job_client = table.get_job_client()
    assert job_client is not None

    table.wait()
    deadline = time.time() + 30
    files = []

    while time.time() < deadline:
        parquet_files = list(tmp_path.rglob("part-*"))
        if parquet_files:
            files = parquet_files
            break
        time.sleep(1)

    assert files, "No parquet files written"

    deadline = time.time() + 15
    while time.time() < deadline:
        files = list(tmp_path.rglob("part-*"))
        if files:
            break
        time.sleep(1)

    assert files, "No parquet files written"
    p = files[0]
    path_str = str(p)

    assert "dt=1970-01-01" in path_str
    assert "hour=00" in path_str

    df = pd.read_parquet(files[0])
    assert len(df) > 0
    assert {
        "event_ts",
        "wiki",
        "type",
        "user_name",
        "bot",
        "title",
        "namespace_id",
    }.issubset(df.columns)
