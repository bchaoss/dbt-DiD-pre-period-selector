{{
  config(
    materialized = 'table',
    tags = ['pre_period_selector']
  )
}}

{%- set post_start = var('pps_post_start_date') -%}

WITH source AS (
  SELECT * FROM {{ ref('int_pps_input_metric') }}
),
gap_series AS (
  SELECT
    w.window_id,
    ROW_NUMBER() OVER (
      PARTITION BY w.window_id ORDER BY d.date
    )                                             AS t,
    d.treated_value - d.control_value             AS gap_value
  FROM {{ ref('int_pps_candidate_windows') }} w
  JOIN source d
    ON d.date BETWEEN w.pre_end
                  AND {{ dbt.dateadd('day', '-1', "CAST('" ~ post_start ~ "' AS DATE)") }}
  WHERE d.is_holiday = false AND d.is_event = false
)
SELECT
  window_id,
  {{ pps_linear_slope('t', 'gap_value') }}  AS gap_slope,
  COUNT(*)                                   AS gap_obs_count
FROM gap_series
GROUP BY window_id