-- Staging: lap_times
-- Available from 1996 onwards. Adds lap_time_seconds for analytics convenience.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_lap_times` AS
SELECT
  raceId        AS race_id,
  driverId      AS driver_id,
  lap           AS lap_number,
  position      AS position_at_lap_end,
  time          AS lap_time_text,
  milliseconds  AS lap_time_ms,
  ROUND(milliseconds / 1000.0, 3) AS lap_time_seconds
FROM `{project}.{raw}.lap_times`;
