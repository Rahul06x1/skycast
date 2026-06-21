-- Typed, deduplicated hourly weather.
-- Unnests the parallel JSON arrays (time / temperature / precipitation) from the raw
-- payload into one row per (city, forecast_ts), keeping the most recent snapshot.

with raw as (
    select city, loaded_at, data
    from {{ source('inbound', 'raw_forecasts') }}
),

unnested as (
    select
        raw.city,
        raw.loaded_at,
        timestamp(json_value(t)) as forecast_ts,
        cast(json_value(temp) as float64) as temperature_c,
        cast(json_value(precip) as float64) as precipitation_mm
    from raw,
        unnest(json_query_array(data, '$.hourly.time')) as t with offset i
    inner join unnest(json_query_array(raw.data, '$.hourly.temperature_2m'))
        as temp with offset ti on i = ti
    inner join unnest(json_query_array(raw.data, '$.hourly.precipitation'))
        as precip with offset pi on i = pi
)

select *
from unnested
{{ dedup(partition_by=['city', 'forecast_ts'], order_by='loaded_at') }}
