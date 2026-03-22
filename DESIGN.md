## Theoretical Background

### The Problem

Difference-in-Differences (DiD) and synthetic control methods require selecting a
pre-period — a historical window used to establish that treated and control groups
moved in parallel before any intervention. Most causal inference literature treats
this selection as a given, leaving practitioners to choose windows manually and
subjectively. This package operationalises the selection criteria that are implicit
in the literature.

---

### Criterion 1 — Differenced Correlation (weight: 0.6)

**What it measures:** Whether treated and control move in the same direction on the
same days — not just whether they are at similar levels.

**Theoretical basis:** The Parallel Trends Assumption (PTA) is the core identifying
assumption of DiD. It requires that in the absence of treatment, the average outcomes
of treated and control groups would have followed parallel paths. A standard empirical
check is the pre-trends test: regress the outcome on time × treatment interactions in
the pre-period and test whether the coefficients are jointly zero (Roth, 2022).

Differenced correlation is a non-parametric operationalisation of this test. Rather
than fitting a regression, it measures the day-over-day co-movement of treated and
control directly. A high differenced correlation (≥ 0.85) indicates that the same
external shocks — seasonality, market conditions, news cycles — affect both groups
similarly, which is the empirical fingerprint of parallel trends.

**Why differencing matters:** Raw level correlation can be spuriously high when both
series share a common upward trend, even if their responses to shocks diverge.
Differencing removes the trend component and isolates co-movement in daily changes,
making the test more stringent.

> Roth, J. (2022). Pre-test with caution: Event-study estimates after testing for
> parallel trends. *American Economic Review: Insights*, 4(3), 305–322.

---

### Criterion 2 — Gap Stability (weight: 0.1)

**What it measures:** Whether the spread between treated and control is drifting
in the period between the pre-period end and the post-period start.

**Theoretical basis:** Even if parallel trends hold within the pre-period, a
divergence in the gap period immediately before the intervention can confound the
treatment effect estimate. This is related to the concept of anticipation effects
discussed in Callaway & Sant'Anna (2021): if units begin to respond to the expected
treatment before it officially starts, the gap between treated and control will show
a trend that is not attributable to the intervention itself.

The gap slope is estimated via OLS on the series (treated − control) over the gap
period. A slope significantly different from zero — flagged at `pps_slope_warning_threshold`
— is a signal that either anticipation effects are present, or that the pre-period
window is too close to a structural break.

> Callaway, B., & Sant'Anna, P. H. C. (2021). Difference-in-differences with
> multiple time periods. *Journal of Econometrics*, 225(2), 200–230.

---

### Criterion 3 — Distance Penalty (weight: 0.3)

**What it measures:** Whether the gap between the pre-period end and the post-period
start is within a range that balances recency and contamination risk.

**Theoretical basis:** The choice of gap length involves a bias-variance tradeoff
that is acknowledged but rarely formalised in the literature.

- **Too short a gap (< 14 days):** The pre-period may overlap with anticipatory
  behaviour or early treatment leakage, violating the no-anticipation assumption
  in Callaway & Sant'Anna (2021). It also leaves insufficient time between the
  measurement window and the intervention for any confounders to settle.

- **Too long a gap (> 45 days):** The pre-period becomes temporally distant from
  the post-period, increasing the risk that the relationship between treated and
  control has structurally changed by the time the intervention occurs. This is
  particularly relevant in settings with fast-moving external conditions such as
  digital products or financial markets.

The optimal range of 14–45 days is a heuristic derived from common practice in
digital experimentation, where treatment effects are typically evaluated over weeks
rather than months, and where platform dynamics can shift meaningfully over a
quarter. This parameter is explicitly configurable via `pps_optimal_gap_min` and
`pps_optimal_gap_max`.

---

### Composite Score

The three criteria are combined as a weighted sum:

```
composite_score =
    0.6 × diff_corr
  + 0.3 × distance_score
  + 0.1 × (1 − normalised |gap_slope|)
```

The weighting reflects the relative importance of each criterion. Parallel trends
is the non-negotiable identifying assumption of DiD — a window that fails this
test cannot be rescued by a good gap length. Distance and gap stability are
secondary, acting as tiebreakers and safeguards rather than primary selectors.

Weights must sum to 1.0 and are validated at compile time. They are fully
configurable via `dbt_project.yml` vars.

---

### What This Package Does Not Do

**Placebo tests.** A natural extension would be to treat each candidate pre-period
as a pseudo-experiment, shift the post-period start to an earlier date within the
pre-period, and verify that no spurious treatment effect is detected. This is a
standard robustness check (Abadie, Diamond & Hainmueller, 2010) and would
strengthen the selection logic. It is not currently implemented.

**Optimal pre-period length via power analysis.** A shorter pre-period reduces
the risk of structural breaks but increases estimation variance. Formalising this
tradeoff via power analysis — as discussed in Imbens & Wooldridge (2009) — is
left for a future version. The current default of 28 days is a heuristic.

**Staggered treatment timing.** The package assumes a single, known treatment
date. For settings with staggered rollouts across units, the Callaway & Sant'Anna
(2021) framework requires a different pre-period selection approach.

**Validated scoring methodology.** The three scoring criteria and their default
weights are engineering judgement, not a validated methodology. There is no
ground truth verification that the recommended window produces more accurate
treatment effect estimates than alternatives. Users should treat
`pps_scored_windows` as input to their own ranking logic
rather than accepting the default composite score uncritically.

**Robustness to noisy metrics.** Differenced correlation is sensitive to
high-frequency noise. If your metric has strong weekly seasonality, consider
setting `pps_diff_lag: 7` to eliminate day-of-week effects before scoring.
For structural noise, smoothing should be applied in the staging model before
passing data to this package.

---

### References

Abadie, A., Diamond, A., & Hainmueller, J. (2010). Synthetic control methods for
comparative case studies. *Journal of the American Statistical Association*,
105(490), 493–505.

Callaway, B., & Sant'Anna, P. H. C. (2021). Difference-in-differences with multiple
time periods. *Journal of Econometrics*, 225(2), 200–230.

Imbens, G. W., & Wooldridge, J. M. (2009). Recent developments in the econometrics
of program evaluation. *Journal of Economic Literature*, 47(1), 5–86.

Roth, J. (2022). Pre-test with caution: Event-study estimates after testing for
parallel trends. *American Economic Review: Insights*, 4(3), 305–322.
