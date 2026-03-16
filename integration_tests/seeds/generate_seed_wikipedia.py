"""
generate_seed_wikipedia.py

Fetches real Wikipedia pageview data from the Wikimedia REST API and writes
it as the integration test seed file.

Scenario
--------
treated : iPhone        (Apple product launch drives spikes)
control : Samsung_Galaxy_S  (correlated consumer electronics interest)
post_start : 2024-03-08  (Samsung Galaxy S24 global launch event)

The pre-period selector will look for windows in the 6 months before the launch
where iPhone and Samsung Galaxy pageviews move together.

Usage
-----
    python seeds/generate_seed_wikipedia.py

Requires: requests (pip install requests)
Output  : seeds/pps_sample_daily_metric.csv
"""

import csv
import json
import time
import urllib.request
from datetime import date, timedelta
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
TREATED_ARTICLE = "iPhone"
CONTROL_ARTICLE = "Samsung_Galaxy_S_series"
START_DATE      = date(2023, 9, 1)
END_DATE        = date(2024, 3, 7)   # day before post_start
POST_START      = date(2024, 3, 8)   # Samsung Galaxy S24 launch event

# US public holidays in the window
HOLIDAYS = {
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
# Fetch
# ---------------------------------------------------------------------------
BASE = "https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article"

def fetch_pageviews(article: str, start: date, end: date) -> dict[str, int]:
    url = (
        f"{BASE}/en.wikipedia/all-access/user/{article}/daily"
        f"/{start.strftime('%Y%m%d')}/{end.strftime('%Y%m%d')}"
    )
    req = urllib.request.Request(url, headers={"User-Agent": "pps-seed-generator/1.0"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
    return {
        item["timestamp"][:8]: item["views"]   # key: YYYYMMDD
        for item in data["items"]
    }

print(f"Fetching pageviews for '{TREATED_ARTICLE}'...")
treated_views = fetch_pageviews(TREATED_ARTICLE, START_DATE, END_DATE)
time.sleep(0.5)   # be polite to the API

print(f"Fetching pageviews for '{CONTROL_ARTICLE}'...")
control_views = fetch_pageviews(CONTROL_ARTICLE, START_DATE, END_DATE)

# ---------------------------------------------------------------------------
# Build rows
# ---------------------------------------------------------------------------
rows = []
d = START_DATE
while d <= END_DATE:
    key = d.strftime("%Y%m%d")
    treated = treated_views.get(key)
    control = control_views.get(key)

    if treated is None or control is None:
        print(f"  Missing data for {d}, skipping")
        d += timedelta(days=1)
        continue

    rows.append({
        "date":           d.isoformat(),
        "treated_value":  treated,
        "control_value":  control,
        "is_holiday":     "true" if d in HOLIDAYS else "false",
    })
    d += timedelta(days=1)

# ---------------------------------------------------------------------------
# Write
# ---------------------------------------------------------------------------
with open(OUTPUT_PATH, "w", newline="") as f:
    writer = csv.DictWriter(
        f, fieldnames=["date", "treated_value", "control_value", "is_holiday"]
    )
    writer.writeheader()
    writer.writerows(rows)

print(f"\nWrote {len(rows)} rows to {OUTPUT_PATH}")
print(f"treated  : {TREATED_ARTICLE}")
print(f"control  : {CONTROL_ARTICLE}")
print(f"window   : {START_DATE} → {END_DATE}")
print(f"post_start (for dbt var): {POST_START}")
print("\nNext steps:")
print("  dbt seed --full-refresh")
print("  dbt build")
print(f"  # set pps_post_start_date: '{POST_START}' in dbt_project.yml")
