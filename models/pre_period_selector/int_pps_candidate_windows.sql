{{
  config(
    materialized = 'table',
    tags = ['pre_period_selector']
  )
}}

{%- set post_start = var('pps_post_start_date') -%}

{%- if post_start is none -%}
  {{ exceptions.raise_compiler_error("pps_post_start_date is not set. Override it via vars in dbt_project.yml.") }}
{%- endif -%}

{% set num_candidates = (var('pps_gap_max_days') / var('pps_slide_interval_days')) | int + 1 %}
{% if num_candidates > var('pps_max_candidates') %}
  {{ log("pps warning: " ~ num_candidates ~ " candidate windows will be generated. Consider increasing pps_slide_interval_days to reduce query complexity.", info=True) }}
{% endif %}

WITH offsets AS (
  {{ pps_generate_window_offsets(num_candidates) }}
),
windows AS (
  SELECT
    offset_index                                             AS window_id,
    offset_index * {{ var('pps_slide_interval_days') }}      AS day_offset,
    {{ dbt.dateadd(
        'day',
        '-(offset_index * ' ~ var('pps_slide_interval_days') ~ ' + ' ~ var('pps_pre_window_days') ~ ')',
        "CAST('" ~ post_start ~ "' AS DATE)"
    ) }}                                                     AS pre_start,
    {{ dbt.dateadd(
        'day',
        '-(offset_index * ' ~ var('pps_slide_interval_days') ~ ' + 1)',
        "CAST('" ~ post_start ~ "' AS DATE)"
    ) }}                                                     AS pre_end
  FROM offsets
)
SELECT
  window_id,
  pre_start,
  pre_end,
  {{ dbt.datediff('pre_end', "CAST('" ~ post_start ~ "' AS DATE)", 'day') }} AS gap_days
FROM windows
WHERE {{ dbt.datediff('pre_end', "CAST('" ~ post_start ~ "' AS DATE)", 'day') }}
      BETWEEN {{ var('pps_gap_min_days') }} AND {{ var('pps_gap_max_days') }}