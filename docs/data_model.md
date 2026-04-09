# Data Model

## Layered architecture (medallion pattern)

```
f1_raw       Bronze   Loaded as-is from CSV. Source-of-truth, never modified.
                      14 tables, ~570k total rows.

f1_staging   Silver   Cleaned views: snake_case columns, derived helper fields,
                      typed correctly. Same grain as raw. 13 views.

f1_marts     Gold     Modelled star schema for analytics. Materialised tables
                      (not views) so Looker Studio queries are fast. 11 tables.
```

## Star schema overview

```
                  ┌─────────────┐
                  │ dim_season  │
                  └──────┬──────┘
                         │
   ┌─────────────┐   ┌───┴────┐   ┌─────────────────┐
   │ dim_circuit ├──→│dim_race│←──┤ dim_constructor │
   └─────────────┘   └───┬────┘   └─────────────────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
        ┌──────────┐┌─────────┐┌──────────┐
        │fct_race_ ││fct_lap_ ││fct_pit_  │
        │results   ││times    ││stops     │
        └────┬─────┘└─────────┘└──────────┘
             │
             ▼
       ┌──────────┐
       │dim_driver│
       └──────────┘
```

## Table grain reference

### Dimensions

| Table | Grain | Notes |
|---|---|---|
| `dim_season` | one row per season | Includes regulation `era` classification |
| `dim_circuit` | one row per circuit | Enriched with first/last/total races hosted |
| `dim_race` | one row per race | Joined to circuit so dashboards skip a join |
| `dim_driver` | one row per driver | Enriched with debut, final season, career span |
| `dim_constructor` | one row per constructor | Enriched with active span and entries |

### Facts

| Table | Grain | Row count (approx) |
|---|---|---|
| `fct_race_results` | driver × race | ~26k |
| `fct_lap_times` | driver × lap (1996+) | ~570k |
| `fct_pit_stops` | pit stop event (2011+) | ~10k |

### Aggregates

| Table | Grain | Powers dashboard page |
|---|---|---|
| `agg_driver_career` | one row per driver | Driver Analytics |
| `agg_constructor_season` | constructor × season | Constructor Era Analysis |
| `agg_circuit_stats` | one row per circuit | Circuit Deep Dive |

## Key derived columns

### `fct_race_results`

- **`is_winner`** — `finish_position = 1`
- **`is_podium`** — `finish_position BETWEEN 1 AND 3`
- **`is_pole_position`** — `grid_position = 1`
- **`is_points_finish`** — `points > 0` (handles all eras since the points
  system has changed many times)
- **`is_dnf`** — status is not `'Finished'` AND not a lapped finish like `+1 Lap`
- **`positions_gained`** — `grid_position - finish_position` (positive = gained)

### `agg_driver_career`

- **`world_championships`** — counted via the season-final standings, not by
  summing wins. A driver who wins the most races in a season but loses the
  championship on tiebreakers is correctly excluded.
- **`win_rate_pct`** — `race_wins / total_races * 100`

### `dim_season.era`

A `CASE` expression maps each season to one of nine F1 regulation eras
(1950-1957 2.5L, 1995-2005 V10, 2014+ Hybrid, etc). Lets dashboards offer
"compare drivers within era" filters that account for the wildly different
points systems across decades.

## Partitioning and clustering

Fact tables are partitioned by `DATE_TRUNC(race_date, MONTH)` and clustered
by the most common filter columns (season, constructor_id, driver_id, or
circuit_id depending on the fact). This keeps Looker Studio queries cheap
even when scanning the full ~600k-row lap times table.

## Refresh

The full mart layer is rebuilt with `make marts` (idempotent — uses
`CREATE OR REPLACE TABLE`). For automated daily refresh, schedule the same
SQL files via BigQuery Scheduled Queries from the console.
