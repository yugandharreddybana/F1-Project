-- Presentation: pres_circuit_deep_dive
--
-- Simplified view for Page 4 of the dashboard.
-- Consolidates circuit stats, locations, and lap-time data.
CREATE OR REPLACE VIEW `{project}.{presentation}.pres_circuit_deep_dive` AS
SELECT
  -- Circuit Metadata
  c.circuit_name,
  c.city,
  c.country,
  c.latitude,
  c.longitude,
  c.total_races_hosted,
  c.avg_pit_stops_per_race,
  c.most_successful_driver,
  c.most_successful_driver_wins,
  c.most_successful_constructor,
  c.most_successful_constructor_wins,
  -- Lap-level detail (Grain: one row per lap)
  l.season,
  l.lap_number,
  l.lap_time_seconds,
  l.driver_name AS lap_driver_name
FROM `{project}.{marts}.agg_circuit_stats` c
LEFT JOIN `{project}.{marts}.fct_lap_times` l USING (circuit_id);
