-- Presentation: pres_constructor_era_analysis
--
-- Simplified view for Page 3 of the dashboard.
-- Maps constructors to eras and pre-calculates championship counts.
CREATE OR REPLACE VIEW `{project}.{presentation}.pres_constructor_era_analysis` AS
SELECT
  c.season,
  s.era,
  c.constructor_name,
  c.total_points,
  c.season_end_position,
  c.won_constructors_championship,
  -- Pre-aggregated total titles for the "Most Successful" table
  SUM(IF(c.won_constructors_championship, 1, 0)) OVER(PARTITION BY c.constructor_name) AS total_constructor_titles
FROM `{project}.{marts}.agg_constructor_season` c
LEFT JOIN `{project}.{marts}.dim_season` s USING (season);
