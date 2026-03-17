#!/bin/bash
set -e

# First time setup
dbt deps
dbt seed

# Run all models and tests
dbt build

# Inspect recommendations
dbt show --select pps_recommendations --output json

psql -h postgres -U dbt -d dbt_test \
  -c "\COPY pps_dev_pre_period_selector.pps_recommendations TO '../examples/data/pps_recommendations.csv' CSV HEADER"

psql -h postgres -U dbt -d dbt_test \
  -c "\COPY pps_dev.pps_sample_daily_metric TO '../examples/data/pps_sample_daily_metric.csv' CSV HEADER"

echo "✅ Done. Open examples/pre_period_recommendations.ipynb to visualise results."