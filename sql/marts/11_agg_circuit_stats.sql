-- Mart: agg_circuit_stats
--
-- One row per circuit. Includes the most successful driver and constructor at
-- each circuit via window functions + QUALIFY. Average pit stops per race uses
-- a sub-query because pit stop data only exists from 2011 onwards.
--
-- Demonstrates: nested CTEs, QUALIFY ROW_NUMBER, conditional joins on partial
-- date ranges, multi-source aggregation.
CREATE OR REPLACE TABLE `{project}.{marts}.agg_circuit_stats` AS
WITH driver_wins_at_circuit AS (
  SELECT
    r.circuit_id,
    f.driver_id,
    f.driver_name,
    COUNT(*) AS wins_here
  FROM `{project}.{marts}.fct_race_results` f
  INNER JOIN `{project}.{marts}.dim_race`   r USING (race_id)
  WHERE f.is_winner
  GROUP BY r.circuit_id, f.driver_id, f.driver_name
),
top_driver_per_circuit AS (
  SELECT
    circuit_id,
    driver_name AS most_successful_driver,
    wins_here   AS most_successful_driver_wins
  FROM driver_wins_at_circuit
  QUALIFY ROW_NUMBER() OVER (PARTITION BY circuit_id ORDER BY wins_here DESC) = 1
),
constructor_wins_at_circuit AS (
  SELECT
    r.circuit_id,
    f.constructor_id,
    f.constructor_name,
    COUNT(*) AS wins_here
  FROM `{project}.{marts}.fct_race_results` f
  INNER JOIN `{project}.{marts}.dim_race`   r USING (race_id)
  WHERE f.is_winner
  GROUP BY r.circuit_id, f.constructor_id, f.constructor_name
),
top_constructor_per_circuit AS (
  SELECT
    circuit_id,
    constructor_name AS most_successful_constructor,
    wins_here        AS most_successful_constructor_wins
  FROM constructor_wins_at_circuit
  QUALIFY ROW_NUMBER() OVER (PARTITION BY circuit_id ORDER BY wins_here DESC) = 1
),
pit_stop_stats AS (
  -- Average pit stops per race per circuit (2011 onwards only)
  SELECT
    r.circuit_id,
    AVG(stops_in_race) AS avg_pit_stops_per_race
  FROM `{project}.{marts}.dim_race` r
  INNER JOIN (
    SELECT race_id, COUNT(*) / COUNT(DISTINCT driver_id) AS stops_in_race
    FROM `{project}.{marts}.fct_pit_stops`
    GROUP BY race_id
  ) ps USING (race_id)
  GROUP BY r.circuit_id
)
SELECT
  c.circuit_id,
  c.circuit_name,
  c.country,
  c.city,
  c.latitude,
  c.longitude,
  c.total_races_hosted,
  c.first_season_hosted,
  c.last_season_hosted,
  td.most_successful_driver,
  td.most_successful_driver_wins,
  tc.most_successful_constructor,
  tc.most_successful_constructor_wins,
  ROUND(ps.avg_pit_stops_per_race, 2) AS avg_pit_stops_per_race
FROM `{project}.{marts}.dim_circuit` c
LEFT JOIN top_driver_per_circuit       td USING (circuit_id)
LEFT JOIN top_constructor_per_circuit  tc USING (circuit_id)
LEFT JOIN pit_stop_stats               ps USING (circuit_id)
WHERE c.total_races_hosted > 0;
