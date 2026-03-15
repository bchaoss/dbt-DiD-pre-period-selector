-- Returns a SQL expression for OLS slope: (n·Σxy - Σx·Σy) / (n·Σx² - (Σx)²)

{% macro pps_linear_slope(x_col, y_col) %}
  (
    COUNT(*) * SUM({{ x_col }} * {{ y_col }}) - SUM({{ x_col }}) * SUM({{ y_col }})
  ) / NULLIF(
    COUNT(*) * SUM({{ x_col }} * {{ x_col }}) - SUM({{ x_col }}) * SUM({{ x_col }}),
    0
  )
{% endmacro %}