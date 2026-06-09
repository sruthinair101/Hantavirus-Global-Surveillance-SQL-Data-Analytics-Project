# 🦠 Hantavirus Global Surveillance — SQL Data Analytics Project

An end-to-end SQL analytics project on a global hantavirus surveillance dataset covering 2,000 cases across 10 countries and 5 virus strains throughout 2025. The project demonstrates a full data analytics workflow — from raw table exploration and cleaning through feature engineering and 15 analytical queries — ready to present as a portfolio piece.


## 🗄️ Database Details

| Attribute        | Value                                                                 |
|------------------|-----------------------------------------------------------------------|
| Database name    | `hantavirus_project`                                                  |
| Table name       | `global_hantavirus_surveillance_dataset_2026`                         |
| Total records    | 2,000                                                                 |
| Columns          | 19 (+ 3 derived)                                                      |
| Time period      | January 2025 – December 2025                                          |
| Countries        | Argentina, Bolivia, Brazil, Canada, Chile, Mexico, Paraguay, Peru, USA, Uruguay |
| Virus strains    | Sin Nombre, Seoul, Dobrava, Puumala, Andes                            |
| Transmission     | Rodent-to-Human, Human-to-Human                                       |
| Exposure sources | Agricultural, Home Infestation, Rodent, Forest, Warehouse, Cruise    |

### Column Reference

| Column                  | Type    | Description                              |
|-------------------------|---------|------------------------------------------|
| `case_id`               | VARCHAR | Unique case identifier                   |
| `country`               | VARCHAR | Country of reported case                 |
| `region`                | VARCHAR | Sub-national region                      |
| `report_date`           | DATE    | Date case was officially reported        |
| `virus_strain`          | VARCHAR | Hantavirus strain identified             |
| `transmission_type`     | VARCHAR | Mode of transmission                     |
| `exposure_source`       | VARCHAR | Where/how patient was exposed            |
| `patient_age`           | INT     | Age in years (range: 12–78)              |
| `gender`                | VARCHAR | Male / Female                            |
| `symptoms`              | TEXT    | Reported clinical symptoms               |
| `hospitalization`       | VARCHAR | Hospitalised? Yes / No                   |
| `fatality`              | VARCHAR | Fatal outcome? Yes / No                  |
| `recovery_days`         | FLOAT   | Days to recovery (155 NULLs → imputed)   |
| `temperature_celsius`   | FLOAT   | Ambient temperature (4.6°C – 47.6°C)     |
| `humidity_percent`      | FLOAT   | Ambient humidity (35% – 95%)             |
| `rodent_presence_index` | INT     | Rodent density index 1–10                |
| `quarantine_days`       | INT     | Days in quarantine (0–21)                |
| `population_density`    | INT     | People per km²                           |
| `air_quality_index`     | INT     | AQI at time of report (20–300)           |

---

## 🔧 SQL Project Workflow

The SQL file is structured in 6 sequential steps:

### Step 1 — Use Database
Selects `hantavirus_project` as the active database. No `CREATE DATABASE` — assumes the DB and imported table already exist.

### Step 2 — Explore Raw Table
Initial profiling before any modifications: row count, previews, distinct values, and numeric summary statistics across all 9 numeric columns.

### Step 3 — Data Cleaning
| Check | Finding | Action |
|---|---|---|
| NULL audit (all 19 columns) | 155 NULLs in `recovery_days` only | Mean imputation via subquery UPDATE |
| Duplicate `case_id` | None found | No action needed |
| Age range validation (0–120) | All records valid (12–78) | No action needed |
| Humidity / temperature bounds | All records valid | No action needed |
| Categorical consistency | Clean Yes/No, Male/Female values | No action needed |

### Step 4 — Feature Engineering
Three new columns derived from existing data:

| New Column      | Type        | Logic                                              |
|-----------------|-------------|----------------------------------------------------|
| `age_group`     | VARCHAR(25) | Segments: Child / Young Adult / Middle Age / Senior |
| `season`        | VARCHAR(10) | Derived from `MONTH(report_date)`                  |
| `high_risk_env` | TINYINT(1)  | 1 if rodent index ≥ 7 AND humidity ≥ 70%, else 0  |

### Step 5 — 15 Analytical Queries
See full question list below.

### Step 6 — Views
Three reusable views created for dashboards and reporting:
- `vw_country_summary` — cases, deaths, fatality rate, hospitalisation rate per country
- `vw_strain_fatality` — fatality rate and recovery time per virus strain
- `vw_monthly_trend` — monthly case volume, deaths, and average recovery days

---

## ❓ 15 Analytical Questions

| #   | Question                                                                 | SQL Concepts Used                        |
|-----|--------------------------------------------------------------------------|------------------------------------------|
| Q1  | Which country reported the highest number of cases?                      | GROUP BY, COUNT, ORDER BY                |
| Q2  | What is the fatality rate per virus strain?                              | Conditional aggregation, percentage calc |
| Q3  | Which transmission type is more common, and does it affect fatality?     | Multi-metric GROUP BY                    |
| Q4  | What is the min / avg / max recovery time by virus strain?               | MIN, AVG, MAX aggregation                |
| Q5  | Which age group has the highest hospitalisation rate?                    | Derived column segmentation, rate calc   |
| Q6  | Does gender influence fatality outcomes?                                 | Demographic breakdown                    |
| Q7  | How does season affect case volume and average recovery time?            | DATE_FORMAT, MONTH grouping              |
| Q8  | Which exposure source leads to the most deaths?                          | Source-level risk ranking                |
| Q9  | Do high-risk environments increase fatality and recovery time?           | Derived flag analysis                    |
| Q10 | Do countries with longer quarantine show lower fatality?                 | Cross-metric country comparison          |
| Q11 | What is the monthly trend in new cases and deaths?                       | Time-series aggregation                  |
| Q12 | How does population density relate to transmission type?                 | CASE bucketing, crosstab                 |
| Q13 | Which virus strain is dominant in each country?                          | Correlated subquery, MAX per group       |
| Q14 | Does Air Quality Index affect recovery time and fatality rate?           | AQI bucketing, multi-metric analysis     |
| Q15 | What are the top 5 highest-risk case profiles?                           | Composite GROUP BY, HAVING, LIMIT        |

---


## 💡 Key Findings

- **7.75% fatality rate** overall (155 out of 2,000 cases).
- **50%+ hospitalisation rate** — indicates moderate-to-severe disease burden across the dataset.
- **155 NULL values** in `recovery_days` — imputed using column mean to preserve analytical completeness.
- **3 derived columns** added (age group, season, high-risk environment flag) to enable segmented analysis not possible from raw columns alone.
- Views created for all three major summary dimensions (country, strain, time) — directly consumable by BI tools like Tableau or Power BI.

---

## 🧰 Tools & Technologies

| Tool             | Purpose                                      |
|------------------|----------------------------------------------|
| MySQL 8.0        | Database engine and query execution          |
| MySQL Workbench  | SQL editor and schema management             |


---

## 📌 SQL Skills Demonstrated

- `USE`, `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`, `HAVING`, `LIMIT`
- `UPDATE` with subquery for NULL imputation
- `ALTER TABLE` + `UPDATE` for feature engineering
- `CASE` expressions for conditional logic and bucketing
- Conditional aggregation: `SUM(CASE WHEN ... END)`
- Date functions: `DATE_FORMAT()`, `MONTH()`
- Correlated subqueries for per-group maximum
- `CREATE OR REPLACE VIEW` for reusable reporting layers
- Data validation queries for NULLs, duplicates, and out-of-range values

Project By Shruti Nair
