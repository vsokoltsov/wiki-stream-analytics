{{ config(materialized='view') }}

select
  case when is_bot then 'bot' else 'human' end as actor_type,
  count(*) as events_total
from {{ ref('stg_recentchange') }}
group by 1
order by events_total desc