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

## Regenerating Seed Data

```bash
python seeds/generate_seed.py
dbt seed --full-refresh
dbt build
```

## Expected Output

`pps_recommendations` should return 3 rows with:
- `diff_corr` above 0.85
- `flag_low_correlation` null
- `flag_unstable_gap` null
- `recommendation_rank` 1 has `gap_days` within 14–45
