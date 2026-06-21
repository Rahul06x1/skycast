{#
  Use the custom schema name verbatim (e.g. `stage`, `marts`) instead of dbt's default
  `<target_schema>_<custom>`. This lets models land in fixed datasets.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
