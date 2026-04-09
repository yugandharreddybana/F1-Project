-- Staging: qualifying
-- Q1, Q2, Q3 are stored as 'M:SS.SSS' strings. Left as strings here; converted
-- to milliseconds in the marts layer where needed.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_qualifying` AS
SELECT
  qualifyId       AS qualifying_id,
  raceId          AS race_id,
  driverId        AS driver_id,
  constructorId   AS constructor_id,
  number          AS car_number,
  position        AS qualifying_position,
  q1              AS q1_time_text,
  q2              AS q2_time_text,
  q3              AS q3_time_text
FROM `{project}.{raw}.qualifying`;
