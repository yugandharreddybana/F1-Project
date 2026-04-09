"""
Centralised configuration. Loads .env and exposes constants used by all scripts.

Importing this module also validates that required environment variables are set
and that the service account key file exists. Fail fast, fail loud.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# Load .env from the repo root regardless of where the script is invoked from
REPO_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(REPO_ROOT / ".env")


def _require(name: str) -> str:
    value = os.getenv(name)
    if not value:
        sys.exit(
            f"ERROR: environment variable {name} is not set. "
            f"Copy .env.example to .env and fill in real values."
        )
    return value


# --- Required settings -------------------------------------------------------

GCP_PROJECT_ID: str = _require("GCP_PROJECT_ID")
GCP_LOCATION: str = _require("GCP_LOCATION")
GCS_BUCKET: str = _require("GCS_BUCKET")
CREDENTIALS_PATH: str = _require("GOOGLE_APPLICATION_CREDENTIALS")

# --- Optional settings (with defaults) ---------------------------------------

BQ_DATASET_RAW: str = os.getenv("BQ_DATASET_RAW", "f1_raw")
BQ_DATASET_STAGING: str = os.getenv("BQ_DATASET_STAGING", "f1_staging")
BQ_DATASET_MARTS: str = os.getenv("BQ_DATASET_MARTS", "f1_marts")
BQ_DATASET_PRESENTATION: str = os.getenv("BQ_DATASET_PRESENTATION", "f1_presentation")

# --- Paths -------------------------------------------------------------------

DATA_RAW_DIR: Path = REPO_ROOT / "data" / "raw"
SQL_DIR: Path = REPO_ROOT / "sql"
DOCS_DIR: Path = REPO_ROOT / "docs"


# --- Validation --------------------------------------------------------------

def validate() -> None:
    """Sanity-check the environment. Called automatically on import."""
    if not Path(CREDENTIALS_PATH).expanduser().exists():
        sys.exit(
            f"ERROR: GOOGLE_APPLICATION_CREDENTIALS points to a file that "
            f"does not exist:\n  {CREDENTIALS_PATH}\n"
            f"Create the service account key with `gcloud iam service-accounts "
            f"keys create ...` and update .env."
        )

    # Make sure the gcloud client libraries can find the key file
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(
        Path(CREDENTIALS_PATH).expanduser().resolve()
    )


validate()
