-- Example staging model showing the expected interface for pps_metric_model
-- Required columns: date, treated_value, control_value, is_holiday
SELECT
    date   AS date,
    treated_value   AS treated_value,
    control_value   AS control_value,
    is_holiday,
    false AS is_event
FROM {{ ref('pps_sample_daily_metric') }}