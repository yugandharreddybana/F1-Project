-- Mart: agg_constructor_season
--
-- Grain: one row per constructor per season.
-- Includes the season-end championship position via QUALIFY on the last race.
CREATE OR REPLACE TABLE `{project}.{marts}.agg_constructor_season` AS
WITH season_finals AS (
  SELECT season, race_id
  FROM `{project}.{marts}.dim_race`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY season ORDER BY round_number DESC) = 1
),
final_standings AS (
  SELECT
    cs.constructor_id,
    sf.season,
    cs.championship_position AS season_end_position,
    cs.points_to_date        AS season_end_points,
    cs.wins_to_date          AS season_end_wins
  FROM `{project}.{staging}.stg_constructor_standings` cs
  INNER JOIN season_finals sf USING (race_id)
),
season_stats AS (
  SELECT
    constructor_id,
    season,
    COUNT(DISTINCT race_id)            AS races_entered,
    COUNTIF(is_winner)                 AS race_wins,
    COUNTIF(is_podium)                 AS podiums,
    COUNTIF(is_pole_position)          AS pole_positions,
    SUM(points)                        AS total_points
  FROM `{project}.{marts}.fct_race_results`
  GROUP BY constructor_id, season
)
SELECT
  ss.season,
  ss.constructor_id,
  c.constructor_name,
  c.nationality              AS constructor_nationality,
  ss.races_entered,
  ss.race_wins,
  ss.podiums,
  ss.pole_positions,
  ROUND(ss.total_points, 1)  AS total_points,
  fs.season_end_position,
  fs.season_end_position = 1 AS won_constructors_championship
FROM season_stats ss
LEFT JOIN `{project}.{marts}.dim_constructor` c USING (constructor_id)
LEFT JOIN final_standings fs
  ON fs.constructor_id = ss.constructor_id AND fs.season = ss.season;
