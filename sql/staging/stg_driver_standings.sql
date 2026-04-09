-- Staging: driver_standings
-- Snapshot of driver championship standings AFTER each race.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_driver_standings` AS
SELECT
  driverStandingsId   AS standing_id,
  raceId              AS race_id,
  driverId            AS driver_id,
  points              AS points_to_date,
  position            AS championship_position,
  positionText        AS championship_position_text,
  wins                AS wins_to_date
FROM `{project}.{raw}.driver_standings`;
