{% test assert_no_date_gaps(model, date_col) %}
SELECT 1
FROM (
    SELECT
        {{ date_col }},
        LAG({{ date_col }}) OVER (ORDER BY {{ date_col }}) AS prev_date
    FROM {{ model }}
    WHERE {{ date_col }} IS NOT NULL
) gaps
WHERE {{ dbt.datediff('prev_date', date_col, 'day') }} > 1
  AND prev_date IS NOT NULL
HAVING COUNT(*) > 0
{% endtest %}