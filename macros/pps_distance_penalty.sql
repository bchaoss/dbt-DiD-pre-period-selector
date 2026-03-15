-- Returns a SQL expression scoring gap proximity to the optimal range [pps_optimal_gap_min, pps_optimal_gap_max]
-- Scores 1.0 within range, linearly penalized outside

{% macro pps_distance_penalty(gap_col) %}
  CASE
    WHEN {{ gap_col }} BETWEEN {{ var('pps_optimal_gap_min') }} AND {{ var('pps_optimal_gap_max') }}
      THEN 1.0
    WHEN {{ gap_col }} < {{ var('pps_optimal_gap_min') }}
      THEN {{ gap_col }} / {{ var('pps_optimal_gap_min') }}.0
    ELSE
      GREATEST(
        0.0,
        1.0 - ({{ gap_col }} - {{ var('pps_optimal_gap_max') }}.0)
              / {{ var('pps_optimal_gap_max') }}.0
      )
  END
{% endmacro %}