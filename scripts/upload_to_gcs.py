"""
Upload every CSV in data/raw/ to a Google Cloud Storage bucket.

Creates the bucket if it does not exist. Idempotent: re-running this script
overwrites the existing files in GCS.
"""

from __future__ import annotations

import sys
from pathlib import Path

from google.api_core.exceptions import Conflict, NotFound
from google.cloud import storage

import config


def get_or_create_bucket(client: storage.Client) -> storage.Bucket:
    """Return the configured bucket, creating it in the right region if needed."""
    try:
        bucket = client.get_bucket(config.GCS_BUCKET)
        print(f"Using existing bucket: gs://{bucket.name}")
        return bucket
    except NotFound:
        print(f"Creating bucket: gs://{config.GCS_BUCKET} in {config.GCP_LOCATION}")
        try:
            bucket = client.create_bucket(
                config.GCS_BUCKET, location=config.GCP_LOCATION
            )
            return bucket
        except Conflict:
            # Race: another process created it. Re-fetch.
            return client.get_bucket(config.GCS_BUCKET)


def upload_file(bucket: storage.Bucket, local_path: Path, blob_name: str) -> None:
    """Upload a single file to the bucket under the given blob name."""
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(str(local_path))
    size_mb = local_path.stat().st_size / (1024 * 1024)
    print(f"  uploaded {blob_name} ({size_mb:.1f} MB)")


def main() -> None:
    csv_files = sorted(config.DATA_RAW_DIR.glob("*.csv"))

    if not csv_files:
        sys.exit(
            f"ERROR: no CSV files found in {config.DATA_RAW_DIR}\n"
            f"Run `make download` first."
        )

    client = storage.Client(project=config.GCP_PROJECT_ID)
    bucket = get_or_create_bucket(client)

    print(f"\nUploading {len(csv_files)} files to gs://{bucket.name}/raw/")
    for path in csv_files:
        upload_file(bucket, path, f"raw/{path.name}")

    print(f"\nDone. {len(csv_files)} files uploaded.")


if __name__ == "__main__":
    main()
