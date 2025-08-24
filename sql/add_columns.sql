-- Add new columns if they don't exist
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS arm TEXT;
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS period TEXT;
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS arm_period TEXT;

-- Convert md5(driver_id) to integer and mod 2 for stable 2-arm split
UPDATE deliveries
SET arm = CASE 
            WHEN ( ('x' || substr(md5(driver_id),1,8))::bit(32)::bigint % 2 ) = 0
            THEN 'treatment' 
            ELSE 'control' 
          END;

-- Assign pre/post period based on pickup_datetime
-- Assuming pickup_datetime is stored like '7/2/2024 6:27'
UPDATE deliveries
SET period = CASE
               WHEN pickup_datetime < TIMESTAMP '2024-07-20' THEN 'pre'
               ELSE 'post'
             END
WHERE pickup_datetime IS NOT NULL;

-- Combine arm and period into arm_period
UPDATE deliveries
SET arm_period = arm || '_' || period;

-- Summary per arm & period (example: count of deliveries)
-- SELECT arm, period, COUNT(*) AS total_deliveries
-- FROM deliveries
-- GROUP BY arm, period
-- ORDER BY arm, period;

-- Preview first 20 rows
SELECT delivery_id, driver_id, pickup_datetime, arm, period, arm_period
FROM deliveries
LIMIT 20;
