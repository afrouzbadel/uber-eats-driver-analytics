# generate_report.py
"""
Usage:
  pip install pandas matplotlib
  python generate_report.py

Produces:
  results/kpis.md
  results/platform_simulation.png
  results/top10_drivers.csv
  results/payout_hist.png
"""
import os
import hashlib
import pandas as pd
import matplotlib.pyplot as plt

# --- تنظیم مسیرها ---
os.makedirs("results", exist_ok=True)
DELIVERIES_CSV = "deliveries_table.csv"
DRIVERS_CSV = "drivers_table.csv"

# --- بارگذاری ---
# --- بارگذاری ---

df = pd.read_csv(r"C:\Users\afrou\OneDrive\Desktop\tableau\uber-eats-driver-analytics\data\deliveries_table.csv", parse_dates=["pickup_datetime","dropoff_datetime"], dayfirst=False)
drivers = pd.read_csv(r"C:\Users\afrou\OneDrive\Desktop\tableau\uber-eats-driver-analytics\data\drivers_table.csv", parse_dates=["join_date"], dayfirst=False)

# --- KPIها ---
kpis = {}
kpis["gmv_order_value"] = df["order_value"].sum()
kpis["total_fare"] = df["fare"].sum()
kpis["platform_take"] = (df["fare"] * df["platform_fee_rate"]).sum()
kpis["driver_earnings_now"] = df["driver_payout"].sum()
kpis["total_tips"] = df["tip"].sum()
kpis["total_trips"] = len(df)
kpis["avg_payout_per_trip"] = df["driver_payout"].mean()
# earnings per hour (per driver aggregated)
per_driver = df.groupby("driver_id").agg(total_earnings=("driver_payout","sum"),
                                         total_minutes=("duration_min","sum")).reset_index()
per_driver["est_hours"] = per_driver["total_minutes"]/60.0
per_driver["earnings_per_hour"] = per_driver["total_earnings"] / per_driver["est_hours"].replace(0, pd.NA)
kpis["avg_earnings_per_hour"] = per_driver["earnings_per_hour"].mean()

# --- Policy simulation (reduce platform_fee_rate by 0.05) ---
fee_delta = -0.05
sim = df.copy()
sim["new_platform_fee"] = (sim["platform_fee_rate"] + fee_delta).clip(lower=0.0)
platform_take_now = (sim["fare"] * sim["platform_fee_rate"]).sum()
platform_take_if = (sim["fare"] * sim["new_platform_fee"]).sum()
driver_earnings_now = sim["driver_payout"].sum()
driver_earnings_if = ((sim["fare"] * (1 - sim["new_platform_fee"])) + sim["tip"]).sum()
delta_total_driver_earnings = driver_earnings_if - driver_earnings_now

# # per-driver impact
# per_driver_sim = sim.groupby("driver_id").agg(
#     trips=("delivery_id","count"),
#     current_earnings=("driver_payout","sum"),
#     earnings_if=(lambda x: (((sim.loc[x.index,"fare"] * (1 - sim.loc[x.index,"new_platform_fee"])) + sim.loc[x.index,"tip"]).sum()))
# ).reset_index()


def per_driver_impact(g):
    cur = g["driver_payout"].sum()
    new = ((g["fare"] * (1 - g["new_platform_fee"])) + g["tip"]).sum()
    return pd.Series(dict(
        trips=len(g),
        current_earnings=cur,
        earnings_if=new,
        earnings_delta=new-cur
    ))

per_driver_sim = sim.groupby("driver_id").apply(per_driver_impact).reset_index()

# The lambda above is tricky in groupby agg; simpler construct:
def per_driver_impact(g):
    cur = g["driver_payout"].sum()
    new = ((g["fare"] * (1 - g["new_platform_fee"])) + g["tip"]).sum()
    return pd.Series(dict(trips=len(g), current_earnings=cur, earnings_if=new, earnings_delta=new-cur))

per_driver_sim = sim.groupby("driver_id").apply(per_driver_impact).reset_index()
top10 = per_driver_sim.sort_values("earnings_delta", ascending=False).head(10)
top10.to_csv("results/top10_drivers.csv", index=False)

# --- AB arm assignment (stable by driver_id using md5) ---
def stable_arm(driver_id):
    h = hashlib.md5(str(driver_id).encode("utf-8")).hexdigest()[:8]
    val = int(h, 16)
    return "treatment" if val % 2 == 0 else "control"

df["arm"] = df["driver_id"].apply(stable_arm)
cutoff = pd.to_datetime("2024-07-20")
df["period"] = df["pickup_datetime"].apply(lambda x: "pre" if pd.notna(x) and x < cutoff else "post")
df["arm_period"] = df["arm"] + "_" + df["period"].astype(str)

# --- خروجی KPI به md ---
with open("results/kpis.md", "w", encoding="utf-8") as f:
    f.write("# KPI Summary\n\n")
    for k,v in kpis.items():
        f.write(f"- **{k}**: {v:.2f}\n")
    f.write("\n## Policy simulation (fee_delta = -0.05)\n")
    f.write(f"- platform_take_now: {platform_take_now:.2f}\n")
    f.write(f"- platform_take_if: {platform_take_if:.2f}\n")
    f.write(f"- driver_earnings_now: {driver_earnings_now:.2f}\n")
    f.write(f"- driver_earnings_if: {driver_earnings_if:.2f}\n")
    f.write(f"- delta_total_driver_earnings: {delta_total_driver_earnings:.2f}\n")

# --- نمودار ساده: platform take now vs if ---
plt.figure(figsize=(5,4))
plt.bar(["now","if"], [platform_take_now, platform_take_if])
plt.title("Platform take: now vs if (fee_delta=-0.05)")
plt.tight_layout()
plt.savefig("results/platform_simulation.png")
plt.close()

# --- histogram driver_payout ---
plt.figure(figsize=(6,4))
plt.hist(df["driver_payout"].dropna(), bins=10)
plt.title("Distribution of driver_payout")
plt.xlabel("driver_payout")
plt.ylabel("count")
plt.tight_layout()
plt.savefig("results/payout_hist.png")
plt.close()

print("Reports generated in results/ (kpis.md, platform_simulation.png, payout_hist.png, top10_drivers.csv)")
