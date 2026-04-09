-- Mart: dim_driver
-- Driver dimension enriched with career span and total race count. Used as the
-- primary lookup table in the Driver Analytics dashboard page.
CREATE OR REPLACE TABLE `{project}.{marts}.dim_driver` AS
SELECT
  d.driver_id,
  d.driver_ref,
  d.driver_code,
  d.first_name,
  d.last_name,
  d.full_name,
  d.date_of_birth,
  d.nationality,
  MIN(r.season)               AS debut_season,
  MAX(r.season)               AS final_season,
  MAX(r.season) - MIN(r.season) + 1 AS career_span_years,
  COUNT(DISTINCT res.race_id) AS total_races_entered,
  d.wikipedia_url
FROM `{project}.{staging}.stg_drivers` d
LEFT JOIN `{project}.{staging}.stg_results` res USING (driver_id)
LEFT JOIN `{project}.{staging}.stg_races`   r   USING (race_id)
GROUP BY
  d.driver_id, d.driver_ref, d.driver_code, d.first_name, d.last_name,
  d.full_name, d.date_of_birth, d.nationality, d.wikipedia_url;
