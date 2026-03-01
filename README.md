# Wikimedia Stream Analytics

## 🎯 Objective

The objective of this project is to design and implement a production-grade, cloud-native real-time data streaming platform that ingests Wikimedia’s public event stream, processes it using distributed stream processing frameworks, and delivers reliable, structured, and analytics-ready datasets to a cloud data warehouse.

The system is built to:
* Ingest high-velocity, unbounded event streams in real time
* Validate, normalize, and enrich semi-structured JSON payloads
* Ensure fault tolerance and processing guarantees (exactly-once semantics, checkpointing, state management)
* Support horizontal scalability under varying traffic conditions
* Enable reproducible deployments via Infrastructure as Code (Terraform, Helm)
* Implement CI/CD pipelines for automated testing and containerized deployment
* Provide a foundation for downstream analytics, BI workloads, and ML feature engineering

The overarching goal is to demonstrate how modern streaming technologies can be combined into a cohesive, scalable, and maintainable data platform aligned with real-world production standards.

## 🧩 Problem Statement

Public real-time event streams (such as Wikimedia’s RecentChange feed) generate high-velocity, semi-structured JSON events that:
* arrive continuously,
* may contain inconsistent fields,
* require validation and normalization,
* must be processed with low latency,
* and need reliable storage for downstream analytics.

The challenge is to design a scalable, cloud-native streaming architecture that:
1. Ingests unbounded event streams reliably
2. Handles schema evolution and malformed records
3. Guarantees processing correctness (at-least-once / exactly-once)
4. Scales horizontally under variable load
5. Integrates with modern data stack components (Kafka/Flink/Beam/BigQuery/dbt)
6. Supports CI/CD and reproducible deployments

Without such architecture, raw streaming data:
* cannot be trusted for analytics,
* is difficult to monitor,
* may lead to data loss or duplication,
* and cannot be reliably used for ML feature pipelines.

## ⚙️ Data Pipeline

Chosen Approach: Streaming

For this project and dataset, a streaming architecture was selected.

The Wikimedia RecentChange feed produces a continuous, unbounded stream of events. Since edits occur in real time and at high frequency, a streaming pipeline allows:
* Immediate ingestion of events from the SSE endpoint
* Low-latency processing via Apache Flink
* Incremental writes to Google Cloud Storage
* Event-driven downstream processing using Pub/Sub and Dataflow
* Near real-time availability of structured data in BigQuery

This approach better reflects modern production-grade data platforms where real-time ingestion, event-driven processing, and scalable stream computation are required.

## Dashboard

* [Looker](https://lookerstudio.google.com/reporting/3808acbe-89ec-47d7-a416-5e74c20fa432)


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


## Data Warehouse

Data Warehouse Optimization

BigQuery is used as the analytical data warehouse.
Tables are explicitly partitioned and clustered based on expected upstream query patterns and data characteristics.

⸻

### 1️⃣ Raw Layer (wikistream_raw.recentchanges)

#### Partitioning

The raw ingestion table is provisioned via Terraform and optimized as follows:

```terraform
time_partitioning {
  type  = "DAY"
  field = "event_ts"
}

require_partition_filter = true
```

##### Why partition by event_ts (DAY)?

* The dataset is a continuous, unbounded event stream.
* Most analytical queries filter by time window (e.g., last 7 days, last 30 days).
* Partitioning by event timestamp ensures:
* Reduced data scanned
* Lower query cost
* Improved performance
* require_partition_filter = true prevents accidental full-table scans.

This is the natural partitioning strategy for streaming event data.

#### Clustering

```
clustering = ["wiki", "namespace_id"]
```

##### Why cluster by wiki and namespace_id?

Typical upstream queries:
* Filter by specific wiki (enwiki, dewiki, etc.)
* Analyze edits per namespace
* Aggregate events by wiki + namespace
* Group by wiki

Clustering on these fields:
* Physically co-locates related rows within partitions
* Reduces scanned blocks when filtering by wiki or namespace
* Improves performance of grouped aggregations

These fields have:
* Moderate cardinality
* High analytical relevance
* Frequent usage in WHERE / GROUP BY clauses

### 2️⃣ Staging Layer (stg_recentchange)

The staging table is built via dbt and further optimized:

```
{{ 
  config(
    materialized = 'table',
    partition_by = {
      "field": "event_date",
      "data_type": "date"
    },
    cluster_by = ["wiki", "event_type", "namespace_id"]
  ) 
}}
```

#### Partitioning by event_date
* Derived from event_ts
* Keeps time-based filtering efficient
* Aligns with common reporting dimensions (daily metrics)

Staging queries frequently apply rolling window filters (e.g., last 30 days), so date partitioning significantly reduces scan size.

#### Clustering by wiki, event_type, namespace_id

These fields are used in:
* Aggregations
* Filtering
* Mart calculations
* BI-style grouping

Example aggregation:

```
group by wiki, event_type, event_date
```

Clustering improves performance for:
* `WHERE wiki = 'enwiki'`
* `WHERE event_type = 'edit'`
* Namespace-level analytics
* Multi-dimensional aggregations

This ensures physical data layout matches analytical access patterns.

### 3️⃣ Mart Layer (Views)

Mart models are implemented as views over the staging table.

Rationale
* The staging table is already partitioned and clustered.
* Views reuse optimized underlying storage.
* No data duplication.
* Keeps transformations lightweight.

If usage patterns evolve (e.g., BI dashboards with heavy repeated queries), marts can be materialized as partitioned & clustered tables.

## Deployment

### Prerequisites

* [Terraform](https://www.hashicorp.com/en/products/terraform)
* [Helm](https://helm.sh/docs/intro/quickstart/)
* [GCloud CLI SDK](https://docs.cloud.google.com/sdk/docs/install-sdk)

### Steps

#### Infrastructure

1. Populate infra/terraform/terraform.tfvars from template `cp infra/terraform/terraform.tfvars.sample infra/terraform/terraform.tfvars` and fill the necessary data
2. Copy GCP service account file to the root folder
3. Run `gcloud auth application-default login` and authenticate
4. `terraform -chdir=infra/terraform plan`
5. `terraform -chdir=infra/terraform apply`

#### Applications

Each example of commands for apps' deployments is located in the Github Actions pipeline for each of the app:
* [producer](./github/workflows/producer.yml)
* [processing](./github/workflows/processing.yml)
* [ingestion](./github/workflows/ingestion.yml)

I strongly recommend to configure proper CI / CD
Necessary environment variables are:

* Secrets:
  * `AP_REPO`
  * `CI_SA_EMAIL`
  * `DATAFLOW_WORKER_SA`
  * `GCP_PROJECT_ID`
  * `GKE_CLUSTER`
  * `HELM_NAMESPACE`
  * `KAFKA_SASL_USERNAME`
  * `PROFILES_YAML`
  * `REGION`
  * `STAGING_BUCKET`
  * `WIF_PROVIDER`
* Envs:
  * `BIGQUERY_TABLE_ID`
  * `PUBSUB_SUBSCRIPTION`
  * `STAGING_LOCATION`
  * `TEMPLATE_GCS`
  * `TEMP_LOCATION`