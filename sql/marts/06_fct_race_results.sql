-- Mart: fct_race_results
--
-- Central fact table. Grain: one row per driver per race.
--
-- Joins results to the status lookup, race metadata, and constructor name so
-- the dashboard can drive most charts off this single table without further
-- joins. Adds derived booleans for the metrics dashboards filter on most:
-- is_winner, is_podium, is_pole_position, is_dnf, points_finish.
--
-- A "DNF" here is anything where status is not 'Finished' AND not a lapped
-- finish (e.g. '+1 Lap', '+2 Laps' are still classified finishes in F1).
CREATE OR REPLACE TABLE `{project}.{marts}.fct_race_results`
PARTITION BY DATE_TRUNC(race_date, MONTH)
CLUSTER BY season, constructor_id, driver_id AS
SELECT
  res.result_id,
  res.race_id,
  r.season,
  r.round_number,
  r.race_name,
  r.race_date,
  res.driver_id,
  d.full_name              AS driver_name,
  d.nationality            AS driver_nationality,
  res.constructor_id,
  c.constructor_name,
  c.nationality            AS constructor_nationality,
  res.grid_position,
  res.finish_position,
  res.finish_position_text,
  res.finish_order,
  res.points,
  res.laps_completed,
  res.race_time_ms,
  res.fastest_lap_time_text,
  res.fastest_lap_speed_kmh,
  res.status_id,
  s.status_description,
  -- Derived flags
  res.grid_position = 1                                              AS is_pole_position,
  res.finish_position = 1                                            AS is_winner,
  res.finish_position BETWEEN 1 AND 3                                AS is_podium,
  res.points > 0                                                     AS is_points_finish,
  s.status_description NOT IN ('Finished')
    AND s.status_description NOT LIKE '+%Lap%'                       AS is_dnf,
  -- Position gained or lost during the race (positive = gained places)
  CASE
    WHEN res.grid_position IS NULL OR res.finish_position IS NULL THEN NULL
    ELSE res.grid_position - res.finish_position
  END                                                                AS positions_gained
FROM `{project}.{staging}.stg_results` res
LEFT JOIN `{project}.{staging}.stg_races`        r USING (race_id)
LEFT JOIN `{project}.{staging}.stg_drivers`      d USING (driver_id)
LEFT JOIN `{project}.{staging}.stg_constructors` c USING (constructor_id)
LEFT JOIN `{project}.{staging}.stg_status`       s USING (status_id);
