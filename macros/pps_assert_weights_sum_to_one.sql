-- Compile-time check: scoring weights must sum to 1.0
-- Call this at the top of pps_recommendations.sql

{% macro pps_assert_weights_sum_to_one() %}
  {%- set total = var('pps_weight_correlation')
                + var('pps_weight_distance')
                + var('pps_weight_gap_stability') -%}
  {%- if (total - 1.0) | abs > 0.001 -%}
    {{ exceptions.raise_compiler_error(
        "Scoring weights must sum to 1.0, current sum is: " ~ total
    ) }}
  {%- endif -%}
{% endmacro %}