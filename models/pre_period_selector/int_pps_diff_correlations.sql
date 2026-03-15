{{
  config(
    materialized = 'table',
    tags = ['pre_period_selector']
  )
}}

{%- set metric_rel = var('pps_metric_relation') -%}
{%- if metric_rel is none -%}
  {{ exceptions.raise_compiler_error("pps_metric_relation is not set. Specify it in vars: pps_metric_relation: ref('your_staging_model')") }}
{%- endif -%}

WITH source AS (
  SELECT * FROM {{ metric_rel }}
),
diffs AS (
  SELECT
    date,
    is_holiday,
    treated_value - LAG(treated_value) OVER (ORDER BY date) AS treated_diff,
    control_value - LAG(control_value) OVER (ORDER BY date) AS control_diff
  FROM source
),
clean_diffs AS (
  SELECT * FROM diffs
  WHERE is_holiday = false
    AND treated_diff IS NOT NULL
    AND control_diff IS NOT NULL
),
windowed AS (
  SELECT
    w.window_id,
    d.treated_diff,
    d.control_diff
  FROM {{ ref('int_pps_candidate_windows') }} w
  JOIN clean_diffs d
    ON d.date BETWEEN w.pre_start AND w.pre_end
)
SELECT
  window_id,
  CORR(treated_diff, control_diff) AS diff_corr,
  COUNT(*)                         AS obs_count
FROM windowed
GROUP BY window_id