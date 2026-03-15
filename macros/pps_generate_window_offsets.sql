{% macro pps_generate_window_offsets(n) %}
  {%- if target.type == 'bigquery' -%}
    SELECT offset_index
    FROM UNNEST(GENERATE_ARRAY(1, {{ n }})) AS offset_index
  {%- elif target.type in ('snowflake', 'duckdb') -%}
    SELECT seq AS offset_index
    FROM TABLE(FLATTEN(INPUT => ARRAY_GENERATE_RANGE(1, {{ n + 1 }})))
  {%- else -%}
    {# Postgres / Redshift / Spark fallback #}
    SELECT generate_series AS offset_index
    FROM generate_series(1, {{ n }})
  {%- endif %}
{% endmacro %}