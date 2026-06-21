{#
  Keep one row per partition key, choosing the most recent by `order_col`.
  Reusable across staging models — mirrors the ROW_NUMBER() ... QUALIFY 1 pattern.

  Usage:
    {{ dedup(partition_by=['city', 'forecast_ts'], order_by='loaded_at') }}
#}
{% macro dedup(partition_by, order_by) -%}
    qualify row_number() over (
        partition by {{ partition_by | join(', ') }}
        order by {{ order_by }} desc
    ) = 1
{%- endmacro %}
