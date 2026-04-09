# 🏎️ F1 Analytics Platform

An end-to-end data engineering project that transforms raw Formula 1 data into deep analytical insights. This platform ingests 70+ years of Ergast F1 data, models it into a high-performance **Star Schema** in GCP, and surfaces metrics via Looker Studio and Power BI.

**Live Dashboard**: [View Looker Studio Report](replace-with-your-url)

---

## 🛠️ The Tech Stack
*   **Engine**: Python 3.11 + Pandas
*   **Infrastructure**: Google Cloud Storage & BigQuery
*   **Modeling**: SQL (CTEs, Window Functions, Partitioning/Clustering)
*   **BI**: Looker Studio & Power BI
*   **Testing**: Pytest for data quality and integrity

---

## 📐 Architecture
This project follows the **Medallion Architecture** to ensure clean data lineage:

1.  **Bronze (Raw)**: Explicitly typed tables in BigQuery.
2.  **Silver (Staging)**: Normalization, cleaning, and `snake_case` standardisation.
3.  **Gold (Marts)**: Optimized Star Schema (`dim_`, `fct_`, `agg_`).
4.  **Platinum (Presentation)**: Custom views optimized for 1:1 mapping with BI dashboards—dramatically reducing dashboard load times.

---

## 🎯 Key Features
*   **Star Schema Design**: Optimized for analytical queries and BI performance.
*   **Automated Pipeline**: A single `make pipeline` command drives everything from data profiling to BI view creation.
*   **Data Quality**: 45+ automated tests verifying row-level grain and business invariants.
*   **Query Performance**: Implemented BigQuery partitioning and clustering to minimize scan costs.

---

## 🚀 Quick Start
For full setup details, see the **[End-to-End Setup Guide](docs/how_to_run.md)**.

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Configure .env with your GCP Project ID
cp .env.example .env

# 3. Spin up the entire pipeline
make pipeline
```

---

## 📂 Project Structure
*   `scripts/`: Python ETL and orchestration logic.
*   `sql/`: Multi-layered transformation logic (Staging, Marts, Presentation).
*   `docs/`: Architecture deep dives, dashboard build guides, and run instructions.
*   `tests/`: Automated data validation suite.

---

## 🎓 Learning More
If you're interested in the "why" behind the design decisions or are preparing for an interview, check out the **[Project Deep Dive](docs/project_deep_dive.md)**.
