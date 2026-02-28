import os
import argparse
import apache_beam as beam
from apache_beam.options.pipeline_options import (
    PipelineOptions,
    SetupOptions,
    StandardOptions,
    WorkerOptions,
)
from ingestion.pipeline.definition import create_ingestion_pipeline


def run(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument(
        "--subscription", required=True
    )  # full path projects/.../subscriptions/...
    ap.add_argument("--table_id", required=True)  # project.dataset.table
    ap.add_argument("--temp_location", required=True)  # gs://.../tmp
    ap.add_argument("--staging_location", required=True)  # gs://.../staging
    ap.add_argument(
        "--sdk_container_image",
        required=False,
        default=None,
        help="Container image for Dataflow workers (e.g. Flex Template image)",
    )
    args, beam_args = ap.parse_known_args(argv)

    options = PipelineOptions(
        beam_args,
        runner="DataflowRunner",
        project=args.project,
        temp_location=args.temp_location,
        staging_location=args.staging_location,
    )
    options.view_as(StandardOptions).streaming = True
    options.view_as(SetupOptions).save_main_session = True
    options.view_as(SetupOptions).sdk_location = "container"
    worker_image = (
        args.sdk_container_image
        or os.environ.get("FLEX_TEMPLATE_IMAGE")
        or os.environ.get("CONTAINER_IMAGE")
    )
    if worker_image:
        options.view_as(WorkerOptions).sdk_container_image = worker_image
    if args.sdk_container_image:
        options.view_as(WorkerOptions).sdk_container_image = args.sdk_container_image

    with beam.Pipeline(options=options) as p:
        create_ingestion_pipeline(p=p, args=vars(args))


if __name__ == "__main__":
    run()
