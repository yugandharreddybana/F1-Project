-- Presentation: pres_championship_overview
--
-- Simplified view for Page 1 of the dashboard.
-- Combines season-level aggregates with driver and constructor standings.
--
-- Logic:
-- 1. Get total races per season
-- 2. Get unique drivers and constructors per season
-- 3. Join with constructor standings
-- 4. Provide a "championship_grain" that works for both scorecards and bars.
CREATE OR REPLACE VIEW `{project}.{presentation}.pres_championship_overview` AS
WITH season_aggregates AS (
  SELECT
    season,
    COUNT(DISTINCT race_id)           AS total_races,
    COUNT(DISTINCT driver_id)         AS total_drivers,
    COUNT(DISTINCT constructor_id)    AS total_constructors
  FROM `{project}.{marts}.fct_race_results`
  GROUP BY season
),
constructor_standings AS (
  SELECT
    season,
    constructor_name,
    total_points,
    season_end_position,
    won_constructors_championship
  FROM `{project}.{marts}.agg_constructor_season`
)
SELECT
  sa.season,
  sa.total_races,
  sa.total_drivers,
  sa.total_constructors,
  cs.constructor_name,
  cs.total_points                    AS constructor_points,
  cs.season_end_position             AS constructor_position,
  cs.won_constructors_championship,
  -- We also pull in the race-level results for the driver bar chart
  rr.driver_name,
  SUM(rr.points) OVER(PARTITION BY sa.season, rr.driver_id) AS driver_season_points
FROM season_aggregates sa
LEFT JOIN constructor_standings cs USING (season)
LEFT JOIN `{project}.{marts}.fct_race_results` rr ON sa.season = rr.season;
