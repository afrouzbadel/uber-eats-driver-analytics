-- CREATE TABLE policy_scenarios (
--   scenario_id TEXT PRIMARY KEY,
--   fee_delta NUMERIC, -- e.g. -0.05 means reduce by 5 percentage points
--   description TEXT
-- );

-- INSERT INTO policy_scenarios VALUES
-- ('baseline', 0.0, 'current policy'),
-- ('fee_minus_5pct', -0.05, 'reduce platform fee by 5 percentage points');


-- 03_policy_simulations.sql
-- Policy simulation: reduce platform fee by 5 percentage points (0.05)
WITH params AS (
  SELECT -0.05::numeric AS fee_delta
),
sim AS (
  SELECT d.*,
         GREATEST(d.platform_fee_rate + params.fee_delta, 0.0) AS new_platform_fee
  FROM deliveries d CROSS JOIN params
)
SELECT
  SUM(fare * platform_fee_rate) AS platform_take_now,
  SUM(fare * new_platform_fee) AS platform_take_if,
  SUM(driver_payout) AS driver_earnings_now,
  SUM( (fare * (1 - new_platform_fee)) + tip ) AS driver_earnings_if,
  SUM( ( (fare * (1 - new_platform_fee)) + tip ) ) - SUM(driver_payout) AS delta_total_driver_earnings
FROM sim;

-- Per-driver impact (top winners)
WITH params AS (SELECT -0.05::numeric AS fee_delta),
sim AS (
  SELECT d.*,
         GREATEST(d.platform_fee_rate + params.fee_delta, 0.0) AS new_platform_fee
  FROM deliveries d CROSS JOIN params
)
SELECT driver_id,
       COUNT(*) AS trips,
       SUM(driver_payout) AS current_earnings,
       SUM( (fare * (1 - new_platform_fee)) + tip ) AS earnings_if,
       SUM( (fare * (1 - new_platform_fee)) + tip ) - SUM(driver_payout) AS earnings_delta
FROM sim
GROUP BY driver_id
ORDER BY earnings_delta DESC
LIMIT 50;

