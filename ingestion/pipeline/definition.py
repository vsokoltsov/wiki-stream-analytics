import os
import argparse
from typing import Dict, Any
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, SetupOptions, StandardOptions, WorkerOptions
from apache_beam.io.gcp.pubsub import ReadFromPubSub

from ingestion.pipeline.parse import parse_notification, is_final_object
from ingestion.pipeline.deduplicate import DeduplicateDoFn
from ingestion.pipeline.routing import add_partition_info
from ingestion.pipeline.stability import WaitForFileStabilityDoFn
from ingestion.pipeline.load import LoadFolderToBQDoFn
from ingestion.pipeline.map_fns import to_dedup_kv, to_completeness_kv

def create_ingestion_pipeline(p: beam.Pipeline, args: Dict[str, Any]):
      """Attach the ingestion DAG to pipeline p. Args hold project, subscription, table_id, etc."""
      events = (
          p
          | "ReadWithAttrs" >> ReadFromPubSub(subscription=args['subscription'], with_attributes=True)
          | "ParseNotification" >> beam.Map(parse_notification)
          | "GrabOnlyFinals" >> beam.Filter(is_final_object)
      )
      deduped = (
          events
          | "KeyForDedup" >> beam.Map(to_dedup_kv)
          | "Deduplicate" >> beam.ParDo(DeduplicateDoFn())
      )
      ready = (
          deduped
          | "KeyForCompleteness" >> beam.Map(to_completeness_kv)
          | "WaitForStableParquet" >> beam.ParDo(
              WaitForFileStabilityDoFn(
                  project_id=args['project'],
                  poll_every_sec=30,
                  stable_needed=2,
              )
          )
      )
      routed = ready | "AddPartitionInfo" >> beam.Map(add_partition_info, table_id=args['table_id'])
      _ = (
          routed
          | "LoadToBigQuery" >> beam.ParDo(LoadFolderToBQDoFn(project_id=args['project']))
      )
      return p