-- Staging: results
-- The main race-results table. positionOrder is always populated; position is
-- NULL for retirements. positionText holds 'R' (retired), 'D' (disqualified),
-- 'F' (failed to qualify), 'W' (withdrew), 'E' (excluded), or a numeric string.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_results` AS
SELECT
  resultId          AS result_id,
  raceId            AS race_id,
  driverId          AS driver_id,
  constructorId     AS constructor_id,
  number            AS car_number,
  grid              AS grid_position,
  position          AS finish_position,
  positionText      AS finish_position_text,
  positionOrder     AS finish_order,
  points,
  laps              AS laps_completed,
  time              AS race_time_text,
  milliseconds      AS race_time_ms,
  fastestLap        AS fastest_lap_number,
  rank              AS fastest_lap_rank,
  fastestLapTime    AS fastest_lap_time_text,
  fastestLapSpeed   AS fastest_lap_speed_kmh,
  statusId          AS status_id
FROM `{project}.{raw}.results`;
