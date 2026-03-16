-- Example staging model showing the expected interface for pps_metric_relation
-- Required columns: date, treated_value, control_value, is_holiday
SELECT
    date   AS date,
    treated_value   AS treated_value,
    control_value   AS control_value,
    is_holiday
FROM {{ ref('pps_sample_daily_metric') }}