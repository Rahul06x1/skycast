-- Forecast stability/accuracy proxy.
-- For each (city, forecast_ts) we compare the EARLIEST forecast we recorded (the
-- "predicted" value) against the LATEST one (the closest-to-actual value). The absolute
-- gap approximates forecast drift. Note: this requires multiple ingestion runs per hour;
-- it is empty until the same forecast_ts has been seen at least twice.

with snapshots as (
    select
        city,
        timestamp(json_value(t)) as forecast_ts,
        loaded_at,
        cast(json_value(temp) as float64) as temperature_c
    from {{ source('inbound', 'raw_forecasts') }} raw,
        unnest(json_query_array(data, '$.hourly.time')) as t with offset i
    inner join unnest(json_query_array(raw.data, '$.hourly.temperature_2m'))
        as temp with offset ti on i = ti
),

ranked as (
    select
        city,
        forecast_ts,
        temperature_c,
        row_number() over (partition by city, forecast_ts order by loaded_at asc) as first_rn,
        row_number() over (partition by city, forecast_ts order by loaded_at desc) as last_rn
    from snapshots
)

select
    f.city,
    f.forecast_ts,
    f.temperature_c as predicted_temp_c,
    l.temperature_c as latest_temp_c,
    round(abs(f.temperature_c - l.temperature_c), 2) as abs_error_c
from ranked f
inner join ranked l
    on f.city = l.city and f.forecast_ts = l.forecast_ts
where f.first_rn = 1 and l.last_rn = 1
    and f.temperature_c != l.temperature_c
