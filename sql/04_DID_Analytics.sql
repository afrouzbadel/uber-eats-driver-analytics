-- 04_ab_analysis.sql
-- NOTE: This assumes 'arm' and 'period' columns are available in deliveries table (or through a view)
-- Example aggregation per arm and period
SELECT arm, period,
       COUNT(*) AS trips,
       SUM(driver_payout) AS total_earnings,
       SUM(driver_payout) / NULLIF(SUM(duration_min)/60.0,0) AS est_earnings_per_hour,
       ROUND( AVG(CASE WHEN tip>0 THEN tip/order_value ELSE 0 END)::numeric,3) AS avg_tip_rate,
       ROUND( SUM(cancelled)::numeric / NULLIF(COUNT(*),0),3) AS cancel_rate
FROM deliveries
GROUP BY arm, period
ORDER BY arm, period;

-- Diff-in-Diff example (earnings/hour)
WITH agg AS (
  SELECT arm, period,
         SUM(driver_payout) AS total_earnings,
         SUM(duration_min)/60.0 AS hours
  FROM deliveries
  GROUP BY arm, period
)
SELECT
  ((SELECT total_earnings/hours FROM agg WHERE arm='treatment' AND period='post')
   - (SELECT total_earnings/hours FROM agg WHERE arm='treatment' AND period='pre'))
  -
  ((SELECT total_earnings/hours FROM agg WHERE arm='control' AND period='post')
   - (SELECT total_earnings/hours FROM agg WHERE arm='control' AND period='pre')) AS diff_in_diff_earnings_per_hour;
