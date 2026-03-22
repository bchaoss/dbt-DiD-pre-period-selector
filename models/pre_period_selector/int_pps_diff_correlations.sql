{{
  config(
    materialized = 'table',
    tags = ['pre_period_selector']
  )
}}

WITH source AS (
  SELECT * FROM {{ ref('int_pps_input_metric') }}
),
diffs AS (
  SELECT
    date,
    is_holiday,
    is_event,
    treated_value - LAG(treated_value, {{ var('pps_diff_lag') }}) OVER (ORDER BY date) AS treated_diff,
    control_value - LAG(control_value, {{ var('pps_diff_lag') }}) OVER (ORDER BY date) AS control_diff
  FROM source
),
clean_diffs AS (
  SELECT * FROM diffs
  WHERE 1=1
    AND is_holiday = false
    AND is_event = false
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