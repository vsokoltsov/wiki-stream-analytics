{{ config(materialized='view') }}

select
  title,
  count(*) as edits
from {{ ref('stg_recentchange') }}
where event_type = 'edit'
group by 1
order by edits desc
limit 10