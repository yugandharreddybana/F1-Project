-- Mart: dim_season
-- Season-level dimension. The `era` column classifies seasons by F1's major
-- regulation periods, useful for "compare drivers fairly across eras" analysis.
--
-- Eras taken from FIA regulation history:
--   1950-1957  Front-engine, 2.5L atmospheric / 750cc supercharged
--   1958-1960  2.5L atmospheric only
--   1961-1965  1.5L atmospheric
--   1966-1986  3.0L atmospheric (with optional 1.5L turbo from 1977)
--   1987-1988  Turbo + 3.5L atmospheric transition
--   1989-1994  3.5L atmospheric only
--   1995-2005  3.0L V10
--   2006-2013  2.4L V8
--   2014-      1.6L V6 turbo hybrid
CREATE OR REPLACE TABLE `{project}.{marts}.dim_season` AS
SELECT
  season,
  CASE
    WHEN season BETWEEN 1950 AND 1957 THEN '1950-1957: 2.5L Era'
    WHEN season BETWEEN 1958 AND 1960 THEN '1958-1960: 2.5L Atmospheric'
    WHEN season BETWEEN 1961 AND 1965 THEN '1961-1965: 1.5L Era'
    WHEN season BETWEEN 1966 AND 1986 THEN '1966-1986: 3.0L Era'
    WHEN season BETWEEN 1987 AND 1988 THEN '1987-1988: Turbo Transition'
    WHEN season BETWEEN 1989 AND 1994 THEN '1989-1994: 3.5L Atmospheric'
    WHEN season BETWEEN 1995 AND 2005 THEN '1995-2005: V10 Era'
    WHEN season BETWEEN 2006 AND 2013 THEN '2006-2013: V8 Era'
    WHEN season >= 2014                THEN '2014-Present: Hybrid Era'
  END AS era,
  wikipedia_url
FROM `{project}.{staging}.stg_seasons`;
