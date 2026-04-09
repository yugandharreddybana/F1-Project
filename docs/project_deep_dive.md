# F1 Analytics: Architecture & Technical Strategy

This guide isn't just about what the code does—it's about the **engineering decisions** that went into building it. If you're explaining this in an interview, focus on the trade-offs.

---

## ⚡ The Quick Pitch
I built a platform that processes 74 years of F1 history (from the 1950s to today). It’s not just a script; it’s a full **Medallion Architecture** pipeline. It takes raw, messy CSVs and turns them into a high-performance **Star Schema** in BigQuery, specifically optimized for BI efficiency.

---

## 🏗️ Technical Architecture

### 1. Bronze (Ingestion)
- **Goal**: Raw data landing.
- **The Work**: I handled the ETL in Python, validating the dataset before pushing it to **Google Cloud Storage (GCS)**.
- **Key Move**: Used explicit BigQuery table schemas during load. "Schema-on-read" is risky; I wanted type safety from day one.

### 2. Silver (Cleaning)
- **Goal**: Normalization.
- **The Work**: SQL views that fix naming and handle F1-specific weirdness (like the source data using `\N` for nulls).
- **Key Move**: Converted everything to standard `snake_case` so the data was actually readable.

### 3. Gold (Modeling)
- **Goal**: High-speed analytics.
- **The Move**: A proper **Star Schema**. I split the data into Dimensions (`dim_`) and Facts (`fct_`).
- **Optimization**: BigQuery can be expensive if you're not careful. I used **Partitioning** and **Clustering** to ensure queries only scan the data they need (like filtering by `season`).

### 4. Platinum (Presentation) 🚀
- **Goal**: Make the dashboard fast.
- **The Move**: I built a "Presentation Layer." Instead of making Looker Studio do heavy joins, I pre-calculated everything in BigQuery views (`pres_*.sql`).
- **Result**: Page load times dropped, and setting up new charts became a simple drag-and-drop exercise.

---

## 🛠️ The Tech Choices: Why these?
- **BigQuery over Postgres?**: Because BQ is serverless. I didn't want to manage indexes or worry about storage limits. It handles millions of rows in milliseconds.
- **Python for ETL?**: It's the standard for GCP integration, and it made the Kaggle API and local file handling seamless.
- **Pytest for Data?**: You can't trust data you don't test. I wrote 45+ tests to verify row counts and business logic (like "did the winner actually finish in P1?").

---

## 💬 Interview "Deep Dive" Questions

### "How do you ensure the data is right?"
> "I don't just check if the script finished. I use **Automated Data Quality Tests**. We check that row counts match across layers and that basic business invariants hold true. If the tests fail, the pipeline stops. No bad data reaches the dashboard."

### "Why use a Star Schema?"
> "It's the industry standard for a reason. It simplifies complex joins into a 'hub-and-spoke' model. It’s easier for BI tools to understand, and it allows BigQuery to execute joins much more efficiently compared to a single massive 'fat' table."

### "What was the hardest part?"
> "Handling BI performance. Initially, the dashboard was slow. I solved this by moving the complexity out of the BI tool and into a **Presentation Layer** in BigQuery. I pre-calculated the heavy aggregations so the dashboard only has to render the data, not compute it."

---

## 🔥 Future Roadmap
- **CI/CD**: Auto-deploy the SQL views using GitHub Actions.
- **Live Ingestion**: Connect to the FastF1 API for real-time practice/qualifying data.
- **Predictive Analytics**: Adding a BQML layer to predict race winners based on qualifying pace.
