-- Example staging model showing the expected interface for pps_metric_relation
-- Required columns: date, treated_value, control_value, is_holiday
SELECT
    event_date   AS date,
    metric_a     AS treated_value,
    metric_b     AS control_value,
    is_holiday
FROM {{ ref('pps_sample_daily_metric') }}