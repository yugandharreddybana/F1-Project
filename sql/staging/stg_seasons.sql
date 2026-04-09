-- Staging: seasons
-- Trivial lookup. Mostly here for completeness so the marts can join cleanly.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_seasons` AS
SELECT
  year  AS season,
  url   AS wikipedia_url
FROM `{project}.{raw}.seasons`;
