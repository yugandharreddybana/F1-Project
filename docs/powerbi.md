# BI Setup: Power BI

By using the `f1_presentation` dataset, you skip the need for complex DAX or record relationships.

## 1. Connection
*   Get Data → **Google BigQuery**.
*   Select the four `pres_*` views from your project.
*   **Mode**: Import (recommended for the best filtering performance).

---

## 2. Dashboard Build Details

### 🗓️ Page 1: Season Statistics
*   **Slicer**: `season`
*   **Cards**: Map `total_races`, `total_drivers`, etc. (Set summarization to `Average` or `Max`).
*   **Chart**: Clustered Bar for Driver/Constructor points.

### 🏆 Page 2: Driver Spotlight
*   **Slicer**: `driver_name`
*   **KPIs**: `race_wins`, `podiums`, `world_championships` (Summarization: `Max`).
*   **Trend**: Line chart showing `points_in_season` over `season`.

### 🏛️ Page 3: Factory & Era Analysis
*   **Slicer**: `era`
*   **Trend**: Multi-line chart for Constructor performance.
*   **Table**: All-time titles filtered by Constructor.

### 🛣️ Page 4: Circuit Analysis
*   **Map Visual**: Use `latitude` and `longitude`.
*   **Performance**: Histogram of `lap_time_seconds`. (Exclude outliers in the Filter pane: > 120s).
