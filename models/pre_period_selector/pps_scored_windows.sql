{{
  config(
    materialized = 'table',
    tags = ['pre_period_selector']
  )
}}

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
    * GREATEST(0.0, 1.0 - (ABS(slope.gap_slope) / {{ var('pps_slope_warning_threshold') }}))
  AS composite_score,

  -- Flags
  CASE WHEN corr.diff_corr < {{ var('pps_corr_warning_threshold') }}
        THEN true END                              AS flag_low_correlation,
  CASE WHEN ABS(slope.gap_slope) > {{ var('pps_slope_warning_threshold') }}
        THEN true END                              AS flag_unstable_gap,
  CASE WHEN corr.obs_count < 14
        THEN true END                              AS flag_low_obs_count

FROM {{ ref('int_pps_candidate_windows') }}  c
LEFT JOIN {{ ref('int_pps_diff_correlations') }} corr USING (window_id)
LEFT JOIN {{ ref('int_pps_gap_slopes') }}        slope USING (window_id)