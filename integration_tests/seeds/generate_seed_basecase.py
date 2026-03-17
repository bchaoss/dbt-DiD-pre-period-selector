import csv
import math
import random
from datetime import date, timedelta

random.seed(42)

holidays = {
    date(2023, 10, 9),   # Columbus Day
    date(2023, 11, 10),  # Veterans Day (observed)
    date(2023, 11, 23),  # Thanksgiving
    date(2023, 11, 24),  # Black Friday
    date(2023, 12, 25),  # Christmas
    date(2023, 12, 26),  # Boxing Day
    date(2024, 1, 1),    # New Year
    date(2024, 1, 15),   # MLK Day
    date(2024, 2, 19),   # Presidents Day
}

rows = []
start = date(2023, 10, 1)
end = date(2024, 3, 31)

treated = 1000.0
control = 950.0

d = start
while d <= end:
    t = (d - start).days

    # shared trend + seasonality
    trend = 0.15 * t
    seasonal = 20 * math.sin(2 * math.pi * t / 7)
    common = trend + seasonal

    # treated tracks common + small independent noise
    treated = 1000 + common + random.gauss(0, 8)
    # control tracks common with slight lag offset + own noise
    control = 950 + common * 0.97 + random.gauss(0, 10)

    is_holiday = "true" if d in holidays else "false"

    rows.append({
        "date": d.isoformat(),
        "treated_value": round(treated, 2),
        "control_value": round(control, 2),
        "is_holiday": is_holiday,
    })
    d += timedelta(days=1)

with open("/workspace/integration_tests/seeds/pps_sample_daily_metric.csv", "w", newline="") as f:
    writer = csv.DictWriter(
        f, fieldnames=["date", "treated_value", "control_value", "is_holiday"])
    writer.writeheader()
    writer.writerows(rows)

print(f"Rows: {len(rows)}")
