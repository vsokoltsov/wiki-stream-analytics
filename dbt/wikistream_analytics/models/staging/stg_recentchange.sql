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
with src as (
  select
    cast(event_ts as timestamp) as event_ts,
    cast(event_ts as date)      as event_date,
    timestamp_trunc(cast(event_ts as timestamp), hour) as event_hour,

    cast(wiki as string)        as wiki,
    cast(type as string)        as event_type,
    cast(user_name as string)        as user_name,
    cast(bot as bool)           as is_bot,
    cast(title as string)       as title,
    cast(namespace_id as int64)   as namespace_id

  from {{ source('raw', 'recentchanges') }}
  where event_ts >= timestamp_sub(current_timestamp(), interval 30 day)
)

select * from src