{{ config(materialized='view') }}

select
  current_date() as day,
  count(*) as events_today,
  countif(event_type = 'edit') as edits_today,
  countif(event_type='edit' and namespace_id = 0) as article_edits_today,
  safe_divide(countif(is_bot), count(*)) as bot_share_today
from {{ ref('stg_recentchange') }}
where event_date = current_date()