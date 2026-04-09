-- Presentation: pres_driver_analytics
--
-- Simplified view for Page 2 of the dashboard.
-- Combines driver biography, career milestones, and season-by-season points.
CREATE OR REPLACE VIEW `{project}.{presentation}.pres_driver_analytics` AS
SELECT
  -- Bio & Career (One row per driver)
  d.driver_name,
  d.nationality,
  d.debut_season,
  d.total_races,
  d.race_wins,
  d.podiums,
  d.pole_positions,
  d.dnfs,
  d.total_career_points,
  d.win_rate_pct,
  d.podium_rate_pct,
  d.world_championships,
  -- Season-by-season performance (Grain: driver per season)
  res.season,
  SUM(res.points)    AS points_in_season,
  COUNT(res.race_id) AS races_in_season,
  COUNTIF(res.is_winner)    AS wins_in_season,
  COUNTIF(res.is_podium)    AS podiums_in_season
FROM `{project}.{marts}.agg_driver_career` d
LEFT JOIN `{project}.{marts}.fct_race_results` res USING (driver_id)
GROUP BY ALL;
