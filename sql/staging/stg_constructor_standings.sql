-- Staging: constructor_standings
-- Snapshot of constructor championship standings AFTER each race.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_constructor_standings` AS
SELECT
  constructorStandingsId  AS standing_id,
  raceId                  AS race_id,
  constructorId           AS constructor_id,
  points                  AS points_to_date,
  position                AS championship_position,
  positionText            AS championship_position_text,
  wins                    AS wins_to_date
FROM `{project}.{raw}.constructor_standings`;
