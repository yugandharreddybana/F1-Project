-- Mart: dim_circuit
-- Circuit dimension enriched with first/last year hosted and total race count.
CREATE OR REPLACE TABLE `{project}.{marts}.dim_circuit` AS
SELECT
  c.circuit_id,
  c.circuit_ref,
  c.circuit_name,
  c.city,
  c.country,
  c.latitude,
  c.longitude,
  c.altitude_m,
  COUNT(DISTINCT r.race_id)  AS total_races_hosted,
  MIN(r.season)              AS first_season_hosted,
  MAX(r.season)              AS last_season_hosted,
  c.wikipedia_url
FROM `{project}.{staging}.stg_circuits` c
LEFT JOIN `{project}.{staging}.stg_races` r
  USING (circuit_id)
GROUP BY
  c.circuit_id, c.circuit_ref, c.circuit_name, c.city, c.country,
  c.latitude, c.longitude, c.altitude_m, c.wikipedia_url;
