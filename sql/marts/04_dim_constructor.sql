-- Mart: dim_constructor
-- Constructor dimension enriched with first/last season and total race entries.
CREATE OR REPLACE TABLE `{project}.{marts}.dim_constructor` AS
SELECT
  c.constructor_id,
  c.constructor_ref,
  c.constructor_name,
  c.nationality,
  MIN(r.season)               AS first_season,
  MAX(r.season)               AS last_season,
  MAX(r.season) - MIN(r.season) + 1 AS active_span_years,
  COUNT(DISTINCT res.race_id) AS total_race_entries,
  c.wikipedia_url
FROM `{project}.{staging}.stg_constructors` c
LEFT JOIN `{project}.{staging}.stg_results` res USING (constructor_id)
LEFT JOIN `{project}.{staging}.stg_races`   r   USING (race_id)
GROUP BY
  c.constructor_id, c.constructor_ref, c.constructor_name, c.nationality,
  c.wikipedia_url;
