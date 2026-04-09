-- Mart: fct_lap_times
--
-- Grain: one row per driver per lap. Available from 1996 onwards (~600k rows).
-- Joined to race and driver context so the dashboard can filter by season,
-- circuit, or driver without further joins. Partitioned and clustered for
-- the lap-time histogram chart on the Circuit Deep Dive page.
CREATE OR REPLACE TABLE `{project}.{marts}.fct_lap_times`
PARTITION BY DATE_TRUNC(race_date, MONTH)
CLUSTER BY season, circuit_id, driver_id AS
SELECT
  lt.race_id,
  r.season,
  r.round_number,
  r.race_name,
  r.race_date,
  r.circuit_id,
  r.circuit_name,
  lt.driver_id,
  d.full_name             AS driver_name,
  lt.lap_number,
  lt.position_at_lap_end,
  lt.lap_time_ms,
  lt.lap_time_seconds
FROM `{project}.{staging}.stg_lap_times` lt
LEFT JOIN `{project}.{marts}.dim_race`     r USING (race_id)
LEFT JOIN `{project}.{staging}.stg_drivers` d USING (driver_id);
