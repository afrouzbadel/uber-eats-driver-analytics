ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS arm TEXT;
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS period TEXT;
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS arm_period TEXT;

-- تبدیل md5(driver_id) به عدد و مد 2 برای ایجاد تقسیم دوگانه پایدار
UPDATE deliveries
SET arm = CASE WHEN ( ('x' || substr(md5(driver_id),1,8))::bit(32)::bigint % 2 ) = 0
               THEN 'treatment' ELSE 'control' END;



-- فرض: pickup_datetime ذخیره شده به صورت مثل '7/2/2024 6:27'
UPDATE deliveries
SET period = CASE
  WHEN pickup_datetime < TIMESTAMP '2024-07-20' THEN 'pre'
  ELSE 'post'
END
WHERE pickup_datetime IS NOT NULL;



UPDATE deliveries
SET arm_period = arm || '_' || period;

-- خلاصه تعداد per arm & period


--
SELECT delivery_id, driver_id, pickup_datetime, arm, period, arm_period
FROM deliveries
LIMIT 20;

