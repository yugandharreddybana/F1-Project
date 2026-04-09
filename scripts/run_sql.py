"""
Execute every .sql file in a folder against BigQuery, in alphabetical order.

Usage:
    python scripts/run_sql.py sql/staging
    python scripts/run_sql.py sql/marts

Templating: each SQL file may use the placeholders {project}, {raw}, {staging},
and {marts}. They are replaced with the values from .env before execution.
"""

from __future__ import annotations

import sys
from pathlib import Path

from google.cloud import bigquery

import config


PLACEHOLDERS: dict[str, str] = {
    "project": config.GCP_PROJECT_ID,
    "raw": config.BQ_DATASET_RAW,
    "staging": config.BQ_DATASET_STAGING,
    "marts": config.BQ_DATASET_MARTS,
    "presentation": config.BQ_DATASET_PRESENTATION,
}


def ensure_target_dataset(client: bigquery.Client, folder_name: str) -> None:
    """Create the target dataset for this SQL folder if it doesn't exist."""
    if folder_name == "staging":
        dataset_name = config.BQ_DATASET_STAGING
        description = "Staging views: cleaned, typed, snake_case. Silver layer."
    elif folder_name == "presentation":
        dataset_name = config.BQ_DATASET_PRESENTATION
        description = "Presentation layer: dashboard-ready views for BI tools. Platinum layer."
    else:
        return  # nothing to create for unknown folders

    dataset_id = f"{config.GCP_PROJECT_ID}.{dataset_name}"
    dataset = bigquery.Dataset(dataset_id)
    dataset.location = config.GCP_LOCATION
    dataset.description = description

    from google.api_core.exceptions import Conflict

    try:
        client.create_dataset(dataset)
        print(f"Created dataset {dataset_id}")
    except Conflict:
        pass  # already exists, no problem


def render(sql_text: str) -> str:
    """Replace {placeholders} with values from PLACEHOLDERS."""
    return sql_text.format(**PLACEHOLDERS)


def run_sql_file(client: bigquery.Client, path: Path) -> None:
    """Execute a single SQL file."""
    sql = render(path.read_text())
    print(f"  running {path.name}...", end=" ", flush=True)
    try:
        job = client.query(sql)
        job.result()
        print("OK")
    except Exception as e:
        print("FAILED")
        sys.exit(f"\nError in {path.name}:\n{e}")


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("Usage: python scripts/run_sql.py <folder>")

    folder = Path(sys.argv[1])
    if not folder.is_dir():
        sys.exit(f"ERROR: {folder} is not a directory")

    sql_files = sorted(folder.glob("*.sql"))
    if not sql_files:
        sys.exit(f"ERROR: no .sql files found in {folder}")

    client = bigquery.Client(
        project=config.GCP_PROJECT_ID, location=config.GCP_LOCATION
    )

    ensure_target_dataset(client, folder.name)

    print(f"\nExecuting {len(sql_files)} SQL files from {folder}")
    for path in sql_files:
        run_sql_file(client, path)

    print(f"\nDone. {len(sql_files)} files executed.")


if __name__ == "__main__":
    main()
