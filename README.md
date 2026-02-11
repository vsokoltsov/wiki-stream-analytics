# Wikimedia Stream Analytics


## Diagram
```
┌──────────────────────────────────────────────┐
│               Wikimedia SSE                  │
│   (public real-time event stream)            │
└──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│              Kafka Producer                  │
│  • long-running service                      │
│  • reads Wikimedia SSE                       │
│  • normalizes / validates JSON               │
│  • acts as streaming ingress                 │
│  • pushes events directly to Flink           │
│    (REST / socket / custom source)           │
└──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│                 Flink                        │
│  • streaming job                             │
│  • consumes events directly from producer    │
│  • parsing / enrichment                      │
│  • watermarking & checkpointing              │
│  • exactly-once semantics (stateful)         │
└──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│                   GCS                        │
│            (Data Lake / Bronze–Silver)       │
│  • immutable Parquet files                   │
│  • partitioned by dt/hour                    │
│  • replay & backfill source                  │
└──────────────────────────────────────────────┘
                    │
        (Object finalize event)
                    │
                    ▼
┌──────────────────────────────────────────────┐
│                 Pub/Sub                      │
│  • file-created notifications                │
│  • event-driven trigger                      │
│  • decouples storage from compute            │
└──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│               Dataflow                       │
│        (Streaming ETL to DWH)                │
│  • subscribes to Pub/Sub                     │
│  • reads newly created GCS objects           │
│  • schema validation / light transforms      │
│  • streaming inserts into BigQuery           │
│  • auto-scaling & fault-tolerant              │
└──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│               BigQuery                       │
│            (Data Warehouse / Gold)           │
│  • near-real-time ingestion                  │
│  • partitioned & clustered tables            │
│  • source of truth for analytics             │
└──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│                    dbt                       │
│  • SQL transformations                       │
│  • facts / dimensions / marts                │
│  • tests & freshness checks                  │
└──────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│                BI / Dashboard                │
│  • near-real-time analytics                  │
│  • business metrics                          │
└──────────────────────────────────────────────┘
```