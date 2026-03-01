{{ config(materialized='view') }}

select
  event_date,
  count(*) as events_total
from {{ ref('stg_recentchange') }}
group by 1
order by 1