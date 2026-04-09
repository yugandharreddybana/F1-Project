-- Staging: sprint_results
-- Sprint races introduced 2021. Same shape as race results.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_sprint_results` AS
SELECT
  resultId          AS sprint_result_id,
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
  fastestLapTime    AS fastest_lap_time_text,
  statusId          AS status_id
FROM `{project}.{raw}.sprint_results`;
