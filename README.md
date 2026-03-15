# did-pre-period-selector

<pre>
dbt_did_pre_period_selector/
├── dbt_project.yml
├── README.md
├── macros/
│   ├── pps_generate_window_offsets.sql   
│   ├── pps_linear_slope.sql              
│   └── pps_distance_penalty.sql          
├── models/
│   └── pre_period_selector/
│       ├── schema.yml
│       ├── int_pps_candidate_windows.sql
│       ├── int_pps_diff_correlations.sql
│       ├── int_pps_gap_slopes.sql
│       ├── int_pps_distance_scores.sql
│       └── pps_recommendations.sql        
├── tests/
│   └── generic/
│       ├── assert_weights_sum_to_one.sql
│       └── assert_top_n_returned.sql
└── integration_tests/
    ├── dbt_project.yml
    ├── seeds/
    │   └── pps_sample_daily_metric.csv
    └── models/
        └── stg_pps_sample_metric.sql
</pre>


## Installation

Add to  `packages.yml`:

```yaml
packages:
  - git: "https://github.com/xxx/did_pre_period_selector"
    revision: 0.1.0
```

Then run:

```bash
dbt deps
```

## Usage

Set the two required variables in `dbt_project.yml`:

```yaml
vars:
  pps_post_start_date: '2024-06-01'
  pps_metric_relation: "ref('stg_my_experiment_metric')"
```

The required staging model must expose these columns:

| Column | Type | Description |
|--------|------|-------------|
| `date` | date | One row per day |
| `treated_value` | numeric | Metric for the treated group |
| `control_value` | numeric | Metric for the control group |
| `is_holiday` | boolean | Days to exclude from scoring |

Then run:

```bash
dbt run  --select pre_period_selector
dbt test --select pre_period_selector
```

Query the output:

```sql
SELECT * FROM pps_recommendations ORDER BY recommendation_rank;
```

Pick the highest rank with no flags raised. 

## Configuration

All variables have defaults and can be overridden in `dbt_project.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `pps_pre_window_days` | 28 | Length of each candidate pre-period |
| `pps_slide_interval_days` | 7 | Step size when sliding the window |
| `pps_num_candidates` | 12 | Number of candidate windows to generate |
| `pps_gap_min_days` | 7 | Minimum days between pre-period end and post-period start |
| `pps_gap_max_days` | 90 | Maximum days between pre-period end and post-period start |
| `pps_optimal_gap_min` | 14 | Lower bound of optimal gap range for distance scoring |
| `pps_optimal_gap_max` | 45 | Upper bound of optimal gap range for distance scoring |
| `pps_weight_correlation` | 0.6 | Weight for differenced correlation score |
| `pps_weight_distance` | 0.3 | Weight for distance penalty score |
| `pps_weight_gap_stability` | 0.1 | Weight for gap stability score |
| `pps_top_n` | 3 | Number of recommendations to return |
| `pps_corr_warning_threshold` | 0.85 | Correlation below this triggers `flag_low_correlation` |
| `pps_slope_warning_threshold` | 0.05 | Slope above this triggers `flag_unstable_gap` |

Weights must sum to 1.0 — enforced at compile time.
