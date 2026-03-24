# Integration Tests

## Local Development

Prerequisites: Docker Desktop, VS Code with Dev Containers extension.

Open the repo in the devcontainer, then:

## Running Integration Tests

```bash
cd integration_tests

# First time setup
dbt deps
dbt seed

# Run all models and tests
dbt build

# Inspect recommendations
dbt show --select pps_recommendations --output json
```

Or

```bash
cd integration_tests
bash test.sh
```

## Expected Output

`pps_recommendations` should return 3 rows with:
- `diff_corr` above 0.85
- `flag_low_correlation` null
- `flag_unstable_gap` null
- `recommendation_rank` 1 has `gap_days` within 14–45

### Validation Tests

Verify flags and guardrails are working:
```bash
# Should fail at compile time: weights do not sum to 1.0
dbt build --vars '{"pps_weight_correlation": 0.8, "pps_weight_distance": 0.3, "pps_weight_gap_stability": 0.1}'

# Should return more rows if enough candidates pass the gap filter
dbt build --vars '{"pps_top_n": 5}'
dbt show --select pps_recommendations --output json

# Should trigger flag_low_correlation on all rows
dbt build --vars '{"pps_corr_warning_threshold": 0.999}'
dbt show --select pps_recommendations --output json
```

## Regenerating Seed Data

```bash
python seeds/generate_seed.py
dbt seed --full-refresh
dbt build
```

### Visualize Output

```bash
# After dbt build, export results for examples
psql -h postgres -U dbt -d dbt_test \
  -c "\COPY pps_dev_pre_period_selector.pps_recommendations TO '../examples/data/pps_recommendations.csv' CSV HEADER"

psql -h postgres -U dbt -d dbt_test \
  -c "\COPY pps_dev.pps_sample_daily_metric TO '../examples/data/pps_sample_daily_metric.csv' CSV HEADER"
```

Then run `show_pre_period_recommendations.ipynb`.