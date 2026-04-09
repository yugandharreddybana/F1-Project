-- Staging: races
-- Renames columns and drops the practice/quali/sprint sub-session timestamps,
-- which are not needed for analytics at the race grain.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_races` AS
SELECT
  raceId      AS race_id,
  year        AS season,
  round       AS round_number,
  circuitId   AS circuit_id,
  name        AS race_name,
  date        AS race_date,
  time        AS race_start_time_utc,
  url         AS wikipedia_url
FROM `{project}.{raw}.races`;
