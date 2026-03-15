-- Fails if the max recommendation_rank exceeds pps_top_n

{% test assert_top_n_returned(model, n_col, expected_max) %}
SELECT 1
FROM {{ model }}
HAVING MAX({{ n_col }}) > {{ expected_max }}
{% endtest %}