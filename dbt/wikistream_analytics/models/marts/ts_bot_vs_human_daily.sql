{{ config(materialized='view') }}

select
  event_date,
  countif(is_bot) as bot_events,
  countif(not is_bot) as human_events
from {{ ref('stg_recentchange') }}
group by 1
order by 1