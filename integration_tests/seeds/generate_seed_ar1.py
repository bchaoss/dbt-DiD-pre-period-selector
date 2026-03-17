"""
generate_seed.py

Replicates the exact data generating process from the CausalImpact R package
vignette (Brodersen et al., 2015):

    set.seed(1)
    x1 <- 100 + arima.sim(model = list(ar = 0.999), n = 100)
    y <- 1.2 * x1 + rnorm(100)
    y[71:100] <- y[71:100] + 10

x1 becomes control_value, y becomes treated_value.
Dates are assigned starting from START_DATE, one row per day.
Post-period starts at day 141 (scaled from 71/100 to fit 200 days).

Note: Python's random module uses a different algorithm than R's Mersenne
Twister, so numeric values differ from the R vignette. The data generating
process (DGP) is identical.

Reference
---------
Brodersen, K.H., Gallusser, F., Koehler, J., Remy, N., Scott, S.L. (2015).
Inferring causal impact using Bayesian structural time-series models.
Annals of Applied Statistics, 9(1), 247-274.

Usage
-----
    python seeds/generate_seed.py

Output
------
    seeds/pps_sample_daily_metric.csv
"""

import csv
import math
import random
from datetime import date, timedelta
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
START_DATE = date(2023, 9, 1)
# total days (vignette uses 100, extended for more candidate windows)
N = 200
# day index (1-based) where post-period starts (mirrors 71/100 split)
POST_DAY = 141
AR_COEF = 0.999     # ar parameter from arima.sim(model = list(ar = 0.999))
X1_BASE = 100       # x1 <- 100 + arima.sim(...)
BETA = 1.2       # y <- 1.2 * x1 + rnorm(100)
TREATMENT = 10        # y[71:100] <- y[71:100] + 10

US_HOLIDAYS = {
    date(2023, 9,  4),   # Labor Day
    date(2023, 10,  9),  # Columbus Day
    date(2023, 11, 10),  # Veterans Day (observed)
    date(2023, 11, 23),  # Thanksgiving
    date(2023, 11, 24),  # Black Friday
    date(2023, 12, 25),  # Christmas
    date(2023, 12, 26),  # Boxing Day
    date(2024, 1,  1),   # New Year
    date(2024, 1, 15),   # MLK Day
    date(2024, 2, 19),   # Presidents Day
}

OUTPUT_PATH = Path(__file__).parent / "pps_sample_daily_metric.csv"

# ---------------------------------------------------------------------------
# Simulate
# ---------------------------------------------------------------------------
random.seed(1)


def rnorm() -> float:
    """Standard normal sample via Box-Muller transform."""
    u1 = random.random()
    u2 = random.random()
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)


# arima.sim(model = list(ar = 0.999), n = N)
x1_sim = []
prev = 0.0
for _ in range(N):
    prev = AR_COEF * prev + rnorm()
    x1_sim.append(prev)

x1 = [X1_BASE + v for v in x1_sim]
y = [BETA * v + rnorm() for v in x1]

# y[POST_DAY:N] <- y[POST_DAY:N] + TREATMENT
for i in range(POST_DAY - 1, N):
    y[i] += TREATMENT

post_start_date = START_DATE + timedelta(days=POST_DAY - 1)

# ---------------------------------------------------------------------------
# Write
# ---------------------------------------------------------------------------
rows = []
for i in range(N):
    d = START_DATE + timedelta(days=i)
    rows.append({
        "date":          d.isoformat(),
        "treated_value": round(y[i], 4),
        "control_value": round(x1[i], 4),
        "is_holiday":    "true" if d in US_HOLIDAYS else "false",
    })

with open(OUTPUT_PATH, "w", newline="") as f:
    writer = csv.DictWriter(
        f, fieldnames=["date", "treated_value", "control_value", "is_holiday"]
    )
    writer.writeheader()
    writer.writerows(rows)

pre_rows = [r for r in rows if r["date"] < post_start_date.isoformat()]
post_rows = [r for r in rows if r["date"] >= post_start_date.isoformat()]

print(f"Wrote {len(rows)} rows to {OUTPUT_PATH}")
print(
    f"  pre-period  : {START_DATE} → {post_start_date - timedelta(days=1)}  ({len(pre_rows)} rows)")
print(
    f"  post-period : {post_start_date} → {START_DATE + timedelta(days=N-1)}  ({len(post_rows)} rows)")
print(f"\nSet in integration_tests/dbt_project.yml:")
print(f"  pps_post_start_date: '{post_start_date}'")
print(f"  pps_corr_warning_threshold: 0.7")
