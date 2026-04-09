-- Staging: pit_stops
-- Available from 2011 onwards. Stop duration in milliseconds is the cleanest field.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_pit_stops` AS
SELECT
  raceId        AS race_id,
  driverId      AS driver_id,
  stop          AS stop_number,
  lap           AS lap_number,
  time          AS stop_time_of_day,
  duration      AS stop_duration_text,
  milliseconds  AS stop_duration_ms,
  ROUND(milliseconds / 1000.0, 3) AS stop_duration_seconds
FROM `{project}.{raw}.pit_stops`;
