-- Mart: agg_driver_career
--
-- One row per driver. Career totals plus a derived "GOAT score" for fun.
-- The world_championships count uses the final standing of each season:
-- a championship is awarded to the driver in position 1 of driver_standings
-- after the LAST race of a season.
--
-- Demonstrates: CTEs, window functions (QUALIFY ROW_NUMBER), conditional
-- aggregation, multi-source joins.
CREATE OR REPLACE TABLE `{project}.{marts}.agg_driver_career` AS
WITH season_finals AS (
  -- Find the LAST race of each season (the round with the highest round_number)
  SELECT
    season,
    race_id
  FROM `{project}.{marts}.dim_race`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY season ORDER BY round_number DESC) = 1
),
season_winners AS (
  -- Drivers who finished P1 in the championship after the last race
  SELECT
    ds.driver_id,
    sf.season
  FROM `{project}.{staging}.stg_driver_standings` ds
  INNER JOIN season_finals sf USING (race_id)
  WHERE ds.championship_position = 1
),
championships_per_driver AS (
  SELECT driver_id, COUNT(*) AS world_championships
  FROM season_winners
  GROUP BY driver_id
),
career_stats AS (
  SELECT
    driver_id,
    COUNT(*)                              AS total_races,
    COUNTIF(is_winner)                    AS race_wins,
    COUNTIF(is_podium)                    AS podiums,
    COUNTIF(is_pole_position)             AS pole_positions,
    COUNTIF(is_points_finish)             AS points_finishes,
    COUNTIF(is_dnf)                       AS dnfs,
    SUM(points)                           AS total_career_points,
    SAFE_DIVIDE(COUNTIF(is_winner),  COUNT(*)) AS win_rate,
    SAFE_DIVIDE(COUNTIF(is_podium), COUNT(*))  AS podium_rate,
    AVG(positions_gained)                 AS avg_positions_gained
  FROM `{project}.{marts}.fct_race_results`
  GROUP BY driver_id
)
SELECT
  d.driver_id,
  d.full_name             AS driver_name,
  d.nationality,
  d.date_of_birth,
  d.debut_season,
  d.final_season,
  d.career_span_years,
  cs.total_races,
  cs.race_wins,
  cs.podiums,
  cs.pole_positions,
  cs.points_finishes,
  cs.dnfs,
  ROUND(cs.total_career_points, 1)  AS total_career_points,
  ROUND(cs.win_rate * 100, 2)       AS win_rate_pct,
  ROUND(cs.podium_rate * 100, 2)    AS podium_rate_pct,
  ROUND(cs.avg_positions_gained, 2) AS avg_positions_gained,
  COALESCE(c.world_championships, 0) AS world_championships
FROM `{project}.{marts}.dim_driver` d
LEFT JOIN career_stats             cs USING (driver_id)
LEFT JOIN championships_per_driver c  USING (driver_id)
WHERE cs.total_races IS NOT NULL;  -- exclude entry-only / withdrawn drivers
