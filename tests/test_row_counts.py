"""
Sanity tests for the F1 analytics pipeline.

Run with `make test`. Verifies that:
  - All raw tables exist and are non-empty
  - Staging views return the same row counts as their raw sources
  - Mart tables exist and are non-empty
  - Key business invariants hold (e.g. every winner has finish_position = 1)

These are not unit tests in the strict sense — they assert against the
real BigQuery dataset after `make pipeline` has run.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from google.cloud import bigquery

# Make scripts/ importable so we can reuse the config module
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import config  # noqa: E402


@pytest.fixture(scope="module")
def client() -> bigquery.Client:
    return bigquery.Client(
        project=config.GCP_PROJECT_ID, location=config.GCP_LOCATION
    )


# -----------------------------------------------------------------------------
# Raw layer
# -----------------------------------------------------------------------------

RAW_TABLES = [
    "circuits", "constructors", "drivers", "races", "results",
    "sprint_results", "qualifying", "pit_stops", "lap_times",
    "driver_standings", "constructor_standings", "constructor_results",
    "seasons", "status",
]


@pytest.mark.parametrize("table", RAW_TABLES)
def test_raw_table_not_empty(client: bigquery.Client, table: str) -> None:
    """Every raw table should have at least one row."""
    sql = f"SELECT COUNT(*) AS n FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_RAW}.{table}`"
    rows = list(client.query(sql).result())
    assert rows[0].n > 0, f"{table} is empty"


# -----------------------------------------------------------------------------
# Staging layer — row counts must match raw
# -----------------------------------------------------------------------------

STAGING_TO_RAW = {
    "stg_circuits":              "circuits",
    "stg_constructors":          "constructors",
    "stg_drivers":               "drivers",
    "stg_races":                 "races",
    "stg_results":               "results",
    "stg_qualifying":            "qualifying",
    "stg_lap_times":             "lap_times",
    "stg_pit_stops":             "pit_stops",
    "stg_driver_standings":      "driver_standings",
    "stg_constructor_standings": "constructor_standings",
    "stg_constructor_results":   "constructor_results",
    "stg_seasons":               "seasons",
    "stg_status":                "status",
    "stg_sprint_results":        "sprint_results",
}


@pytest.mark.parametrize("staging,raw", list(STAGING_TO_RAW.items()))
def test_staging_row_counts_match_raw(
    client: bigquery.Client, staging: str, raw: str
) -> None:
    """Staging is non-destructive: row counts must equal the raw source."""
    sql = f"""
    SELECT
      (SELECT COUNT(*) FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_RAW}.{raw}`) AS raw_n,
      (SELECT COUNT(*) FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_STAGING}.{staging}`) AS stg_n
    """
    row = list(client.query(sql).result())[0]
    assert row.raw_n == row.stg_n, (
        f"{staging} has {row.stg_n} rows but raw {raw} has {row.raw_n}"
    )


# -----------------------------------------------------------------------------
# Marts — existence and basic invariants
# -----------------------------------------------------------------------------

MART_TABLES = [
    "dim_season", "dim_circuit", "dim_driver", "dim_constructor", "dim_race",
    "fct_race_results", "fct_lap_times", "fct_pit_stops",
    "agg_driver_career", "agg_constructor_season", "agg_circuit_stats",
]


@pytest.mark.parametrize("table", MART_TABLES)
def test_mart_table_not_empty(client: bigquery.Client, table: str) -> None:
    sql = f"SELECT COUNT(*) AS n FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_MARTS}.{table}`"
    rows = list(client.query(sql).result())
    assert rows[0].n > 0, f"mart {table} is empty"


def test_winners_have_finish_position_one(client: bigquery.Client) -> None:
    """Every row flagged is_winner must have finish_position = 1."""
    sql = f"""
    SELECT COUNT(*) AS bad
    FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_MARTS}.fct_race_results`
    WHERE is_winner AND finish_position != 1
    """
    assert list(client.query(sql).result())[0].bad == 0


def test_world_champions_count_is_plausible(client: bigquery.Client) -> None:
    """Total championships across all drivers should equal number of seasons completed."""
    sql = f"""
    SELECT
      (SELECT SUM(world_championships)
         FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_MARTS}.agg_driver_career`) AS total_titles,
      (SELECT COUNT(DISTINCT season)
         FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_MARTS}.fct_race_results`) AS total_seasons
    """
    row = list(client.query(sql).result())[0]
    # Should be within 1 of each other (current season may be incomplete)
    assert abs(row.total_titles - row.total_seasons) <= 1, (
        f"Sum of championships ({row.total_titles}) does not match "
        f"number of seasons ({row.total_seasons})"
    )

# -----------------------------------------------------------------------------
# Presentation layer
# -----------------------------------------------------------------------------

PRES_VIEWS = [
    "pres_championship_overview",
    "pres_driver_analytics",
    "pres_constructor_era_analysis",
    "pres_circuit_deep_dive",
]


@pytest.mark.parametrize("view", PRES_VIEWS)
def test_pres_view_not_empty(client: bigquery.Client, view: str) -> None:
    """Every presentation view should return data."""
    sql = f"SELECT COUNT(*) AS n FROM `{config.GCP_PROJECT_ID}.{config.BQ_DATASET_PRESENTATION}.{view}`"
    rows = list(client.query(sql).result())
    assert rows[0].n > 0, f"presentation view {view} is empty"
