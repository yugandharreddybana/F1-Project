-- Mart: fct_pit_stops
--
-- Grain: one row per pit stop. Available from 2011 onwards.
-- Joined to race and driver context for direct dashboard consumption.
CREATE OR REPLACE TABLE `{project}.{marts}.fct_pit_stops`
PARTITION BY DATE_TRUNC(race_date, MONTH)
CLUSTER BY season, constructor_id AS
SELECT
  ps.race_id,
  r.season,
  r.round_number,
  r.race_name,
  r.race_date,
  r.circuit_id,
  r.circuit_name,
  ps.driver_id,
  d.full_name        AS driver_name,
  res.constructor_id,
  c.constructor_name,
  ps.stop_number,
  ps.lap_number,
  ps.stop_duration_ms,
  ps.stop_duration_seconds
FROM `{project}.{staging}.stg_pit_stops` ps
LEFT JOIN `{project}.{marts}.dim_race`           r   USING (race_id)
LEFT JOIN `{project}.{staging}.stg_drivers`      d   USING (driver_id)
-- Pull constructor via the results table (a driver's team can change race-to-race)
LEFT JOIN `{project}.{staging}.stg_results`      res
  ON res.race_id = ps.race_id AND res.driver_id = ps.driver_id
LEFT JOIN `{project}.{staging}.stg_constructors` c USING (constructor_id);
