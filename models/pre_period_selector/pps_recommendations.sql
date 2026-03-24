{{ pps_assert_weights_sum_to_one() }}

{{
  config(
    materialized = 'table',
    tags = ['pre_period_selector']
  )
}}

WITH ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY composite_score DESC) AS recommendation_rank,
  FROM {{ ref('pps_scored_windows') }}
  WHERE diff_corr IS NOT NULL
      AND diff_corr > {{ var('pps_corr_min_threshold') }}
)
SELECT
  recommendation_rank,
  pre_start,
  pre_end,
  gap_days,
  ROUND(diff_corr::numeric,    4) AS diff_corr,
  ROUND(gap_slope::numeric,    4) AS gap_slope,
  ROUND(distance_score::numeric, 4) AS distance_score,
  ROUND(composite_score::numeric, 4) AS composite_score,
  flag_low_correlation,
  flag_unstable_gap,
  flag_low_obs_count,
  window_id
FROM ranked
WHERE recommendation_rank <= {{ var('pps_top_n') }}
ORDER BY recommendation_rank