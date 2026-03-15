{{ pps_assert_weights_sum_to_one() }}

{{
  config(
    materialized = 'table',
    tags = ['pre_period_selector']
  )
}}

WITH scored AS (
  SELECT
    c.window_id,
    c.pre_start,
    c.pre_end,
    c.gap_days,

    corr.diff_corr,
    corr.obs_count,
    slope.gap_slope,

    {{ pps_distance_penalty('c.gap_days') }}        AS distance_score,

    -- Composite weighted score (gap stability is inverted and normalised)
    {{ var('pps_weight_correlation') }}  * COALESCE(corr.diff_corr, 0)
    + {{ var('pps_weight_distance') }}   * {{ pps_distance_penalty('c.gap_days') }}
    + {{ var('pps_weight_gap_stability') }}
      * (1.0 - ABS(slope.gap_slope) / NULLIF(
          MAX(ABS(slope.gap_slope)) OVER (), 0)
        )                                           AS composite_score

  FROM {{ ref('int_pps_candidate_windows') }}  c
  LEFT JOIN {{ ref('int_pps_diff_correlations') }} corr USING (window_id)
  LEFT JOIN {{ ref('int_pps_gap_slopes') }}        slope USING (window_id)
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY composite_score DESC) AS recommendation_rank,

    -- Flags
    CASE WHEN diff_corr < {{ var('pps_corr_warning_threshold') }}
         THEN true END                              AS flag_low_correlation,
    CASE WHEN ABS(gap_slope) > {{ var('pps_slope_warning_threshold') }}
         THEN true END                              AS flag_unstable_gap,
    CASE WHEN obs_count < 14
         THEN true END                              AS flag_low_obs_count
  FROM scored
  WHERE diff_corr IS NOT NULL
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