# dbt-DiD-Pre-Period-Selector

## What This Package Does

Selecting a pre-treatment period for Difference-in-Differences (DiD) is typically done
manually. 
This `dbt` package **automates the selection by scoring candidate
historical windows** against three criteria in SQL: 
- how closely treated and control co-move
(differenced correlation);
- how stable the gap between them is leading into the
experiment (gap slope);
- and how far the window sits from the post-period start
(distance penalty).

Given a *metric table* and an *experiment start date*, it returns the **top-N recommended
pre-treatment periods**, with ranked scores and quality flags for human review.

## Design Philosophy

The package aims the **window selection problem** for pre-treatment period in DiD, instead of pre-trends hypothesis testing problem.

The treated and control groups are assumed and already defined by the
analyst, for examples: YoY
comparisons, matched markets, or synthetic controls. 

The question being answered is: *given these two series, which historical
window provides the most stable and parallel baseline?*

This is distinct from the pre-trends testing critique in Roth (2022), which applies
to settings where a test result determines whether analysis proceeds. Here, a window
is always selected. The package finds the best available one and flags its
weaknesses transparently.

For the full theoretical references and known limitations, see [background.md](background.md).


## Installation

dbt version required: `>=1.3.0, <2.0.0`

Include the following in dbt `packages.yml` file:

```yaml
packages:
  - git: "https://github.com/bchaoss/dbt-did-pre-period-selector"
    revision: 0.1.0
```

Run `dbt deps` to install the package.



## Usage

Set the two required variables in `dbt_project.yml`:

```yaml
vars:
  pps_post_start_date: '2024-06-01'                # experiment start date
  pps_metric_relation: 'stg_my_experiment_metric'  # input model name
```

### Staging model interface

The package expects a staging model with these columns:

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `date` | date | ✓ | One row per day |
| `treated_value` | numeric | ✓ | Metric for the treated group |
| `control_value` | numeric | ✓ | Metric for the control group |
| `is_holiday` | boolean | ✓ | Set to `false` if not applicable |
| `is_event` | boolean | ✓ | Set to `false` if not applicable |

Minimal example:
```sql
-- stg_my_experiment_metric.sql
SELECT
    date             AS date,
    metric_treated   AS treated_value,
    metric_control   AS control_value,
    false,           AS is_holiday,
    false            AS is_event
FROM {{ ref('your_source') }}
```

### Running the package

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

### Multiple Control Groups

If have more than one control group, aggregate them in the staging model
before passing to the package. The package expects a single `control_value` column.

For example:
```sql
-- stg_my_experiment_metric.sql
SELECT
    date,
    treated_value,
    (control_a + control_b + control_c) / 3.0 AS control_value,
    is_holiday
FROM {{ ref('your_source') }}
```


## Structure

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


## Configuration

**Compatibility**: Tested on Postgres. Compatible with Snowflake, BigQuery, Redshift, and DuckDB
via dbt's cross-database macros (`dbt.dateadd`, `dbt.datediff`).


All variables have defaults and can be overridden in `dbt_project.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `pps_pre_window_days` | 28 | Length of each candidate pre-period |
| `pps_slide_interval_days` | 7 | Step size when sliding the window |
| `pps_gap_min_days` | 7 | Minimum days between pre-period end and post-period start |
| `pps_gap_max_days` | 90 | Maximum days between pre-period end and post-period start |
| `pps_optimal_gap_min` | 14 | Lower bound of optimal gap range for distance scoring |
| `pps_optimal_gap_max` | 45 | Upper bound of optimal gap range for distance scoring |
| `pps_weight_correlation` | 0.6 | Weight for differenced correlation score* |
| `pps_weight_distance` | 0.3 | Weight for distance penalty score* |
| `pps_weight_gap_stability` | 0.1 | Weight for gap stability score* |
| `pps_top_n` | 3 | Number of recommendations to return |
| `pps_corr_warning_threshold` | 0.85 | Correlation below this triggers `flag_low_correlation` |
| `pps_slope_warning_threshold` | 0.05 | Slope above this triggers `flag_unstable_gap` |

*Weights must sum to 1.0 — enforced at compile time.
