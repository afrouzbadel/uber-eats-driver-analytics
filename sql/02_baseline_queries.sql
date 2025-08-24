SELECT
  SUM(order_value) AS gmv,
  SUM(fare) AS total_fare,
  SUM(fare * platform_fee_rate) AS platform_take,
  SUM(driver_payout) AS driver_earnings,
  SUM(tip) AS total_tips,
  ROUND(SUM(driver_payout)::numeric,2) AS driver_earnings_rounded
FROM deliveries;


SELECT
  COUNT(*) as total_trips,
  ROUND(AVG(driver_payout)::numeric,2) AS avg_payout_per_trip
FROM deliveries;




WITH per_driver AS (
  SELECT driver_id,
         SUM(driver_payout) AS total_earnings,
         SUM(duration_min)/60.0 AS est_hours_worked
  FROM deliveries
  GROUP BY driver_id
)
SELECT
  AVG(total_earnings / NULLIF(est_hours_worked,0)) AS avg_earnings_per_hour
FROM per_driver;



