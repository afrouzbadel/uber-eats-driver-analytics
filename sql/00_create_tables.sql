CREATE TABLE drivers (
  driver_id TEXT PRIMARY KEY,
  join_date DATE,
  city TEXT,
  vehicle_type TEXT,
  acceptance_rate NUMERIC,
  avg_weekly_hours INT,
  delivered_trips INT,
  total_earnings NUMERIC,
  avg_payout_per_trip NUMERIC,
  avg_rating NUMERIC
);

CREATE TABLE deliveries (
  delivery_id TEXT PRIMARY KEY,
  driver_id TEXT REFERENCES drivers(driver_id),
  pickup_datetime TIMESTAMP,
  dropoff_datetime TIMESTAMP,
  distance_km NUMERIC,
  duration_min INT,
  order_value NUMERIC,
  fare NUMERIC,
  surge_multiplier NUMERIC,
  platform_fee_rate NUMERIC,
  tip NUMERIC,
  driver_payout NUMERIC,
  rating NUMERIC,
  cancelled INT,
  city TEXT
);
