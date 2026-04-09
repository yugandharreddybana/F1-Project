-- Staging: constructors
-- Renames columns to snake_case. No business logic at the staging layer.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_constructors` AS
SELECT
  constructorId   AS constructor_id,
  constructorRef  AS constructor_ref,
  name            AS constructor_name,
  nationality,
  url             AS wikipedia_url
FROM `{project}.{raw}.constructors`;
