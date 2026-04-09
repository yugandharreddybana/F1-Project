-- Staging: circuits
-- Cleans the raw circuits table. Renames columns to snake_case.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_circuits` AS
SELECT
  circuitId   AS circuit_id,
  circuitRef  AS circuit_ref,
  name        AS circuit_name,
  location    AS city,
  country,
  lat         AS latitude,
  lng         AS longitude,
  alt         AS altitude_m,
  url         AS wikipedia_url
FROM `{project}.{raw}.circuits`;
