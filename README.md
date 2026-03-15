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