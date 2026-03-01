{{ config(materialized='view') }}

select
  namespace_id,
  count(*) as events_total
from {{ ref('stg_recentchange') }}
group by 1
order by events_total desc