select
  event_date,
  count(*) as events_total,
  countif(is_bot) as events_by_bots,
  countif(not is_bot) as events_by_humans
from {{ ref('stg_recentchange') }}
where event_date >= date_sub(current_date(), interval 30 day)
group by 1
order by 1