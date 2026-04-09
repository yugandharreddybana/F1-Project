-- Mart: dim_race
-- Race dimension joined to circuit so dashboards don't need extra joins.
CREATE OR REPLACE TABLE `{project}.{marts}.dim_race` AS
SELECT
  r.race_id,
  r.season,
  r.round_number,
  r.race_name,
  r.race_date,
  r.race_start_time_utc,
  c.circuit_id,
  c.circuit_name,
  c.country  AS circuit_country,
  c.city     AS circuit_city,
  c.latitude AS circuit_latitude,
  c.longitude AS circuit_longitude,
  r.wikipedia_url
FROM `{project}.{staging}.stg_races` r
LEFT JOIN `{project}.{staging}.stg_circuits` c USING (circuit_id);
