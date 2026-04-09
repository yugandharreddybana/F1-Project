# End-to-End Execution Guide

This guide covers everything you need to get the F1 Analytics Platform running from scratch. 

## 🏗️ 1. Infrastructure Setup (GCP)

Before running the code, you need a place for the data to land.

1.  **Create a GCP Project**: Go to the [GCP Console](https://console.cloud.google.com/) and create a project (e.g., `f1-analytics-project`).
2.  **Enable Billing**: Ensure billing is enabled (the Free Tier is plenty for this project).
3.  **Enable APIs**: 
    ```bash
    gcloud services enable bigquery.googleapis.com storage.googleapis.com
    ```
4.  **Service Account**: Create a service account and grant it these roles:
    *   `BigQuery Data Editor`
    *   `BigQuery Job User`
    *   `Storage Admin`
5.  **Generate Key**: Save the JSON key to a secure location (e.g., `~/.gcp/f1-key.json`).

---

## 🐍 2. Local Environment Setup

1.  **Python**: Ensure you have Python 3.11 installed.
2.  **Virtual Env**:
    ```bash
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    ```
3.  **Configuration**: Copy `.env.example` to `.env` and fill in your Project ID and the path to your service account key.
    ```bash
    cp .env.example .env
    # Edit .env with your real Project ID and Key Path
    ```

---

## 🏎️ 3. Execution Pipeline

You can run the entire system with one command:

```bash
make pipeline
```

### What happens under the hood?
1.  **`make profile`**: Scans the 14 raw CSVs and generates a data quality report.
2.  **`make upload`**: Creates a GCS bucket and uploads the CSVs.
3.  **`make load-raw`**: Moves data from GCS into BigQuery (Bronze layer).
4.  **`make staging`**: Runs SQL to clean and normalize the data (Silver layer).
5.  **`make marts`**: Builds the Star Schema (Gold layer).
6.  **`make presentation`**: Creates simplified views for BI tools (Platinum layer).

---

## ✅ 4. Verification

Always run the test suite after a pipeline run to ensure nothing broke:

```bash
make test
```
*Look for "45 passed" in the output.*

---

## 📊 5. Visualization

Choose your tool and connect to the **`f1_presentation`** dataset:
- **Looker Studio**: See [docs/dashboard.md](dashboard.md)
- **Power BI**: See [docs/powerbi.md](powerbi.md)

---

## 🆘 Troubleshooting

- **"Module not found"**: Ensure you've activated your virtual environment (`source .venv/bin/activate`).
- **"Access Denied"**: Double-check that your Service Account has the correct roles in the GCP Console.
- **"Dataset not found"**: The script creates these for you, but ensure your `GCP_LOCATION` in `.env` (e.g., `US` or `EU`) matches your project's regional settings.
