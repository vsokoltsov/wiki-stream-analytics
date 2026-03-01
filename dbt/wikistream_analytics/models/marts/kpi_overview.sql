{{ config(materialized='view') }}

with base as (
  select *
  from {{ ref('stg_recentchange') }}
)

select
  current_timestamp() as computed_at,
  count(*) as total_events,
  countif(event_type = 'edit') as total_edits,
  safe_divide(countif(is_bot), count(*)) as bot_share,
  count(distinct user_name) as unique_users,
  count(distinct title) as unique_pages
from base