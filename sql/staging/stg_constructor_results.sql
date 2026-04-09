-- Staging: constructor_results
-- Per-race points contributed by each constructor (sum across both cars).
CREATE OR REPLACE VIEW `{project}.{staging}.stg_constructor_results` AS
SELECT
  constructorResultsId  AS constructor_result_id,
  raceId                AS race_id,
  constructorId         AS constructor_id,
  points                AS race_points,
  status                AS race_status
FROM `{project}.{raw}.constructor_results`;
