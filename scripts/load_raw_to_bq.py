"""
Load every CSV from GCS into BigQuery with explicit, hand-defined schemas.

We do NOT use autodetect because:
  - Ergast time columns like '1:34.567' are strings, not durations
  - Some 'time' columns mix HH:MM:SS and floats — autodetect picks INT and breaks
  - The '\\N' null marker confuses type inference for sparse columns

Each table has its schema defined in TABLE_SCHEMAS below. Adding a new source
file is a one-line change.
"""

from __future__ import annotations

import sys

from google.api_core.exceptions import Conflict
from google.cloud import bigquery

import config

# -----------------------------------------------------------------------------
# Schemas
# -----------------------------------------------------------------------------
# All Ergast CSVs have a header row. Nullable unless the column is a primary key
# or otherwise guaranteed populated. The '\N' null marker is handled via
# null_marker on the LoadJobConfig.
# -----------------------------------------------------------------------------

SF = bigquery.SchemaField  # alias for brevity

TABLE_SCHEMAS: dict[str, list[bigquery.SchemaField]] = {
    "circuits": [
        SF("circuitId", "INT64", "REQUIRED"),
        SF("circuitRef", "STRING", "REQUIRED"),
        SF("name", "STRING", "REQUIRED"),
        SF("location", "STRING"),
        SF("country", "STRING"),
        SF("lat", "FLOAT64"),
        SF("lng", "FLOAT64"),
        SF("alt", "INT64"),
        SF("url", "STRING"),
    ],
    "constructors": [
        SF("constructorId", "INT64", "REQUIRED"),
        SF("constructorRef", "STRING", "REQUIRED"),
        SF("name", "STRING", "REQUIRED"),
        SF("nationality", "STRING"),
        SF("url", "STRING"),
    ],
    "drivers": [
        SF("driverId", "INT64", "REQUIRED"),
        SF("driverRef", "STRING", "REQUIRED"),
        SF("number", "INT64"),
        SF("code", "STRING"),
        SF("forename", "STRING", "REQUIRED"),
        SF("surname", "STRING", "REQUIRED"),
        SF("dob", "DATE"),
        SF("nationality", "STRING"),
        SF("url", "STRING"),
    ],
    "races": [
        SF("raceId", "INT64", "REQUIRED"),
        SF("year", "INT64", "REQUIRED"),
        SF("round", "INT64", "REQUIRED"),
        SF("circuitId", "INT64", "REQUIRED"),
        SF("name", "STRING", "REQUIRED"),
        SF("date", "DATE"),
        SF("time", "STRING"),
        SF("url", "STRING"),
        SF("fp1_date", "DATE"),
        SF("fp1_time", "STRING"),
        SF("fp2_date", "DATE"),
        SF("fp2_time", "STRING"),
        SF("fp3_date", "DATE"),
        SF("fp3_time", "STRING"),
        SF("quali_date", "DATE"),
        SF("quali_time", "STRING"),
        SF("sprint_date", "DATE"),
        SF("sprint_time", "STRING"),
    ],
    "results": [
        SF("resultId", "INT64", "REQUIRED"),
        SF("raceId", "INT64", "REQUIRED"),
        SF("driverId", "INT64", "REQUIRED"),
        SF("constructorId", "INT64", "REQUIRED"),
        SF("number", "INT64"),
        SF("grid", "INT64"),
        SF("position", "INT64"),       # NULL when DNF
        SF("positionText", "STRING"),  # 'R', 'D', 'F', or numeric
        SF("positionOrder", "INT64", "REQUIRED"),
        SF("points", "FLOAT64"),
        SF("laps", "INT64"),
        SF("time", "STRING"),          # '1:34:56.789' or '+1.234'
        SF("milliseconds", "INT64"),
        SF("fastestLap", "INT64"),
        SF("rank", "INT64"),
        SF("fastestLapTime", "STRING"),
        SF("fastestLapSpeed", "FLOAT64"),
        SF("statusId", "INT64", "REQUIRED"),
    ],
    "sprint_results": [
        SF("resultId", "INT64", "REQUIRED"),
        SF("raceId", "INT64", "REQUIRED"),
        SF("driverId", "INT64", "REQUIRED"),
        SF("constructorId", "INT64", "REQUIRED"),
        SF("number", "INT64"),
        SF("grid", "INT64"),
        SF("position", "INT64"),
        SF("positionText", "STRING"),
        SF("positionOrder", "INT64", "REQUIRED"),
        SF("points", "FLOAT64"),
        SF("laps", "INT64"),
        SF("time", "STRING"),
        SF("milliseconds", "INT64"),
        SF("fastestLap", "INT64"),
        SF("fastestLapTime", "STRING"),
        SF("statusId", "INT64", "REQUIRED"),
    ],
    "qualifying": [
        SF("qualifyId", "INT64", "REQUIRED"),
        SF("raceId", "INT64", "REQUIRED"),
        SF("driverId", "INT64", "REQUIRED"),
        SF("constructorId", "INT64", "REQUIRED"),
        SF("number", "INT64"),
        SF("position", "INT64"),
        SF("q1", "STRING"),
        SF("q2", "STRING"),
        SF("q3", "STRING"),
    ],
    "pit_stops": [
        SF("raceId", "INT64", "REQUIRED"),
        SF("driverId", "INT64", "REQUIRED"),
        SF("stop", "INT64", "REQUIRED"),
        SF("lap", "INT64", "REQUIRED"),
        SF("time", "STRING"),
        SF("duration", "STRING"),
        SF("milliseconds", "INT64"),
    ],
    "lap_times": [
        SF("raceId", "INT64", "REQUIRED"),
        SF("driverId", "INT64", "REQUIRED"),
        SF("lap", "INT64", "REQUIRED"),
        SF("position", "INT64"),
        SF("time", "STRING"),
        SF("milliseconds", "INT64"),
    ],
    "driver_standings": [
        SF("driverStandingsId", "INT64", "REQUIRED"),
        SF("raceId", "INT64", "REQUIRED"),
        SF("driverId", "INT64", "REQUIRED"),
        SF("points", "FLOAT64"),
        SF("position", "INT64"),
        SF("positionText", "STRING"),
        SF("wins", "INT64"),
    ],
    "constructor_standings": [
        SF("constructorStandingsId", "INT64", "REQUIRED"),
        SF("raceId", "INT64", "REQUIRED"),
        SF("constructorId", "INT64", "REQUIRED"),
        SF("points", "FLOAT64"),
        SF("position", "INT64"),
        SF("positionText", "STRING"),
        SF("wins", "INT64"),
    ],
    "constructor_results": [
        SF("constructorResultsId", "INT64", "REQUIRED"),
        SF("raceId", "INT64", "REQUIRED"),
        SF("constructorId", "INT64", "REQUIRED"),
        SF("points", "FLOAT64"),
        SF("status", "STRING"),
    ],
    "seasons": [
        SF("year", "INT64", "REQUIRED"),
        SF("url", "STRING"),
    ],
    "status": [
        SF("statusId", "INT64", "REQUIRED"),
        SF("status", "STRING", "REQUIRED"),
    ],
}


def ensure_dataset(client: bigquery.Client) -> None:
    """Create the f1_raw dataset if it doesn't exist."""
    dataset_id = f"{config.GCP_PROJECT_ID}.{config.BQ_DATASET_RAW}"
    dataset = bigquery.Dataset(dataset_id)
    dataset.location = config.GCP_LOCATION
    dataset.description = "Raw F1 data loaded from Kaggle (Ergast mirror). Bronze layer."

    try:
        client.create_dataset(dataset)
        print(f"Created dataset {dataset_id} in {config.GCP_LOCATION}")
    except Conflict:
        print(f"Dataset {dataset_id} already exists")


def load_table(
    client: bigquery.Client,
    table_name: str,
    schema: list[bigquery.SchemaField],
) -> int:
    """Load a single CSV from GCS into a BigQuery table. Returns row count."""
    table_id = f"{config.GCP_PROJECT_ID}.{config.BQ_DATASET_RAW}.{table_name}"
    uri = f"gs://{config.GCS_BUCKET}/raw/{table_name}.csv"

    job_config = bigquery.LoadJobConfig(
        schema=schema,
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        null_marker="\\N",
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        allow_quoted_newlines=True,
    )

    print(f"  loading {table_name}...", end=" ", flush=True)
    load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)
    load_job.result()  # block until done

    table = client.get_table(table_id)
    print(f"{table.num_rows:,} rows")
    return table.num_rows


def main() -> None:
    client = bigquery.Client(
        project=config.GCP_PROJECT_ID, location=config.GCP_LOCATION
    )

    ensure_dataset(client)

    print(f"\nLoading {len(TABLE_SCHEMAS)} tables into {config.BQ_DATASET_RAW}")
    total = 0
    for table_name, schema in TABLE_SCHEMAS.items():
        try:
            total += load_table(client, table_name, schema)
        except Exception as e:
            sys.exit(f"\nFAILED loading {table_name}: {e}")

    print(f"\nDone. {len(TABLE_SCHEMAS)} tables loaded, {total:,} total rows.")


if __name__ == "__main__":
    main()
