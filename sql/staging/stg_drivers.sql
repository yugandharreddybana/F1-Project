-- Staging: drivers
-- Adds full_name as a convenience derived column.
CREATE OR REPLACE VIEW `{project}.{staging}.stg_drivers` AS
SELECT
  driverId                          AS driver_id,
  driverRef                         AS driver_ref,
  number                            AS car_number,
  code                              AS driver_code,
  forename                          AS first_name,
  surname                           AS last_name,
  CONCAT(forename, ' ', surname)    AS full_name,
  dob                               AS date_of_birth,
  nationality,
  url                               AS wikipedia_url
FROM `{project}.{raw}.drivers`;
