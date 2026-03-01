{{ config(materialized='view') }}

select
  wiki,
  event_type,
  event_date,

  count(*) as events_total,

  countif(is_bot) as bot_events,
  countif(not is_bot) as human_events,

  safe_divide(countif(is_bot), count(*)) as bot_share

from {{ ref('stg_recentchange') }}

group by 1, 2, 3
order by wiki, events_total desc