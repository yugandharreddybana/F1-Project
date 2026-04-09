# BI Setup: Looker Studio

To save time, connect to the `f1_presentation` dataset. All joins and math are already handled there.

## 1. Data Connection
1. New Report → **BigQuery** connector.
2. Add these views from `f1_presentation`:
   - `pres_championship_overview` (Page 1)
   - `pres_driver_analytics` (Page 2)
   - `pres_constructor_era_analysis` (Page 3)
   - `pres_circuit_deep_dive` (Page 4)

---

## 2. Page Configuration Checklist

### 🏁 Page 1: Championship Overview
*   **Data Source**: `pres_championship_overview`
*   **Filter**: `season` (Drop-down)
*   **Metrics (MAX)**: `total_races`, `total_drivers`, `total_constructors`
*   **Charts**: 
    - Driver Standings: `driver_name` vs `driver_season_points`
    - Constructor Standings: `constructor_name` vs `constructor_points`

### 🏎️ Page 2: Driver Analytics
*   **Data Source**: `pres_driver_analytics`
*   **Filter**: `driver_name` (Search/Drop-down)
*   **High-level (MAX)**: `race_wins`, `podiums`, `world_championships`
*   **Time-Series**: `season` vs `points_in_season`

### 🏗️ Page 3: Constructor History
*   **Data Source**: `pres_constructor_era_analysis`
*   **Filter**: `era`
*   **Visuals**:
    - Line chart: `season` vs `total_points` (Breakdown: `constructor_name`)
    - Leaderboard: `constructor_name` vs `total_constructor_titles` (MAX)

### 📍 Page 4: Circuit Deep Dive
*   **Data Source**: `pres_circuit_deep_dive`
*   **Filter**: `circuit_name`
*   **Visuals**:
    - Map: Use `latitude` and `longitude`
    - Histogram: `lap_time_seconds` vs `COUNT(*)` (Set bins to 1 second)
