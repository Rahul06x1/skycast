-- Daily temperature & precipitation summary per city.
-- Partitioned by date and clustered by city for cheap, pruned queries.

{{
    config(
        partition_by={'field': 'weather_date', 'data_type': 'date'},
        cluster_by=['city'],
    )
}}

select
    city,
    date(forecast_ts) as weather_date,
    min(temperature_c) as min_temp_c,
    max(temperature_c) as max_temp_c,
    round(avg(temperature_c), 2) as avg_temp_c,
    round(sum(precipitation_mm), 2) as total_precip_mm,
    count(*) as hours_observed
from {{ ref('weather_typed') }}
group by city, weather_date
