-- Staging: status
-- Lookup of finish-status descriptions: 'Finished', '+1 Lap', 'Engine',
-- 'Collision', 'Disqualified', etc. Used by marts to classify DNFs.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_status` AS
SELECT
  statusId  AS status_id,
  status    AS status_description
FROM `{project}.{raw}.status`;
