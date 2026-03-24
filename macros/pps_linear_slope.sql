-- Returns a SQL expression for OLS slope: (n·Σxy - Σx·Σy) / (n·Σx² - (Σx)²)

{% macro pps_linear_slope(x_col, y_col) %}
  COVAR_POP({{ y_col }}, {{ x_col }}) / NULLIF(VAR_POP({{ x_col }}), 0)
{% endmacro %}