-- ============================================================
-- HANTAVIRUS GLOBAL SURVEILLANCE — SQL DATA ANALYTICS PROJECT
-- Database  : hantavirus_project
-- Table     : global_hantavirus_surveillance_dataset_2026
-- Records   : 2,000  |  Columns : 19  |  Countries : 10
-- Period    : January 2025 – December 2025
-- ============================================================


-- ============================================================
-- STEP 1 : USE DATABASE
-- ============================================================
Create database hantavirus_project;
USE hantavirus_project;


-- ============================================================
-- STEP 2 : EXPLORE THE RAW TABLE
-- ============================================================

-- 2a. Preview first 10 rows
SELECT * FROM global_hantavirus_surveillance_dataset_2026 LIMIT 10;

-- 2b. Total row count
SELECT COUNT(*) AS total_records
FROM global_hantavirus_surveillance_dataset_2026;

-- 2c. All distinct countries
SELECT DISTINCT country
FROM global_hantavirus_surveillance_dataset_2026
ORDER BY country;

-- 2d. All distinct virus strains
SELECT DISTINCT virus_strain
FROM global_hantavirus_surveillance_dataset_2026;

-- 2e. Column-level summary statistics for numeric columns
SELECT
    ROUND(AVG(patient_age), 2)            AS avg_age,
    MIN(patient_age)                       AS min_age,
    MAX(patient_age)                       AS max_age,
    ROUND(AVG(recovery_days), 2)          AS avg_recovery_days,
    ROUND(AVG(temperature_celsius), 2)    AS avg_temp_celsius,
    ROUND(AVG(humidity_percent), 2)       AS avg_humidity_pct,
    ROUND(AVG(rodent_presence_index), 2)  AS avg_rodent_index,
    ROUND(AVG(quarantine_days), 2)        AS avg_quarantine_days,
    ROUND(AVG(air_quality_index), 2)      AS avg_aqi
FROM global_hantavirus_surveillance_dataset_2026;


-- ============================================================
-- STEP 3 : DATA CLEANING
-- ============================================================

-- -----------------------------------------------
-- 3a. Check NULLs across all key columns
-- -----------------------------------------------
SELECT
    SUM(CASE WHEN case_id            IS NULL THEN 1 ELSE 0 END) AS null_case_id,
    SUM(CASE WHEN country            IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN region             IS NULL THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN report_date        IS NULL THEN 1 ELSE 0 END) AS null_report_date,
    SUM(CASE WHEN virus_strain       IS NULL THEN 1 ELSE 0 END) AS null_virus_strain,
    SUM(CASE WHEN transmission_type  IS NULL THEN 1 ELSE 0 END) AS null_transmission_type,
    SUM(CASE WHEN exposure_source    IS NULL THEN 1 ELSE 0 END) AS null_exposure_source,
    SUM(CASE WHEN patient_age        IS NULL THEN 1 ELSE 0 END) AS null_patient_age,
    SUM(CASE WHEN gender             IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN hospitalization    IS NULL THEN 1 ELSE 0 END) AS null_hospitalization,
    SUM(CASE WHEN fatality           IS NULL THEN 1 ELSE 0 END) AS null_fatality,
    SUM(CASE WHEN recovery_days      IS NULL THEN 1 ELSE 0 END) AS null_recovery_days,
    SUM(CASE WHEN temperature_celsius IS NULL THEN 1 ELSE 0 END) AS null_temperature,
    SUM(CASE WHEN humidity_percent   IS NULL THEN 1 ELSE 0 END) AS null_humidity,
    SUM(CASE WHEN air_quality_index  IS NULL THEN 1 ELSE 0 END) AS null_aqi
FROM global_hantavirus_surveillance_dataset_2026;
-- Result: 155 NULLs in recovery_days only — all other columns are complete

-- -----------------------------------------------
-- 3b. Fill NULL recovery_days with column average
-- -----------------------------------------------
UPDATE global_hantavirus_surveillance_dataset_2026
SET recovery_days = (
    SELECT avg_val FROM (
        SELECT ROUND(AVG(recovery_days), 2) AS avg_val
        FROM global_hantavirus_surveillance_dataset_2026
        WHERE recovery_days IS NOT NULL
    ) AS sub
)
WHERE recovery_days IS NULL;

-- Confirm: should now return 0
SELECT COUNT(*) AS remaining_nulls_recovery_days
FROM global_hantavirus_surveillance_dataset_2026
WHERE recovery_days IS NULL;

-- -----------------------------------------------
-- 3c. Check for duplicate case IDs
-- -----------------------------------------------
SELECT case_id, COUNT(*) AS frequency
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY case_id
HAVING COUNT(*) > 1;
-- No duplicates expected — case_id is unique per record

-- -----------------------------------------------
-- 3d. Validate patient_age range (expected 0–120)
-- -----------------------------------------------
SELECT COUNT(*) AS invalid_age_records
FROM global_hantavirus_surveillance_dataset_2026
WHERE patient_age <= 0 OR patient_age > 120;
-- Dataset range: 12–78, all valid

-- -----------------------------------------------
-- 3e. Validate humidity and temperature ranges
-- -----------------------------------------------
SELECT COUNT(*) AS invalid_env_records
FROM global_hantavirus_surveillance_dataset_2026
WHERE humidity_percent < 0   OR humidity_percent > 100
   OR temperature_celsius < -50 OR temperature_celsius > 60;
-- Dataset: humidity 35–95, temp 4.6–47.6, all valid

-- -----------------------------------------------
-- 3f. Confirm categorical column consistency
-- -----------------------------------------------
SELECT DISTINCT hospitalization FROM global_hantavirus_surveillance_dataset_2026;
SELECT DISTINCT fatality        FROM global_hantavirus_surveillance_dataset_2026;
SELECT DISTINCT gender          FROM global_hantavirus_surveillance_dataset_2026;
SELECT DISTINCT transmission_type FROM global_hantavirus_surveillance_dataset_2026;
-- All return clean Yes/No or Male/Female values — no casing issues


-- ============================================================
-- STEP 4 : FEATURE ENGINEERING  (new derived columns)
-- ============================================================

-- -----------------------------------------------
-- 4a. Add age_group column
-- -----------------------------------------------
ALTER TABLE global_hantavirus_surveillance_dataset_2026
ADD COLUMN age_group VARCHAR(25);

UPDATE global_hantavirus_surveillance_dataset_2026
SET age_group = CASE
    WHEN patient_age < 18              THEN 'Child (0-17)'
    WHEN patient_age BETWEEN 18 AND 35 THEN 'Young Adult (18-35)'
    WHEN patient_age BETWEEN 36 AND 59 THEN 'Middle Age (36-59)'
    ELSE                                    'Senior (60+)'
END;

-- -----------------------------------------------
-- 4b. Add season column from report_date
-- -----------------------------------------------
ALTER TABLE global_hantavirus_surveillance_dataset_2026
ADD COLUMN season VARCHAR(10);

UPDATE global_hantavirus_surveillance_dataset_2026
SET season = CASE
    WHEN MONTH(report_date) IN (12, 1, 2) THEN 'Winter'
    WHEN MONTH(report_date) IN (3, 4, 5)  THEN 'Spring'
    WHEN MONTH(report_date) IN (6, 7, 8)  THEN 'Summer'
    ELSE                                       'Autumn'
END;

-- -----------------------------------------------
-- 4c. Add high_risk_env flag
--     (rodent index >= 7 AND humidity >= 70%)
-- -----------------------------------------------
ALTER TABLE global_hantavirus_surveillance_dataset_2026
ADD COLUMN high_risk_env TINYINT(1);

UPDATE global_hantavirus_surveillance_dataset_2026
SET high_risk_env = CASE
    WHEN rodent_presence_index >= 7 AND humidity_percent >= 70 THEN 1
    ELSE 0
END;

-- Verify new columns
SELECT age_group, season, high_risk_env,
       COUNT(*) AS records
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY age_group, season, high_risk_env
ORDER BY age_group, season
LIMIT 12;


-- ============================================================
-- STEP 5 : ANALYTICAL QUERIES — 15 QUESTIONS
-- ============================================================

-- -------------------------------------------------------
-- Q1.  Which country reported the highest number of cases?
-- -------------------------------------------------------
SELECT
    country,
    COUNT(*)  AS total_cases
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY country
ORDER BY total_cases DESC;

-- -------------------------------------------------------
-- Q2.  What is the fatality rate per virus strain?
-- -------------------------------------------------------
SELECT
    virus_strain,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS fatal_cases,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY virus_strain
ORDER BY fatality_rate_pct DESC;

-- -------------------------------------------------------
-- Q3.  Which transmission type is more common, and does
--      it lead to higher fatality?
-- -------------------------------------------------------
SELECT
    transmission_type,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS deaths,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY transmission_type
ORDER BY total_cases DESC;

-- -------------------------------------------------------
-- Q4.  What is the average recovery time by virus strain?
-- -------------------------------------------------------
SELECT
    virus_strain,
    COUNT(*)                              AS total_cases,
    ROUND(MIN(recovery_days), 2)          AS min_recovery_days,
    ROUND(AVG(recovery_days), 2)          AS avg_recovery_days,
    ROUND(MAX(recovery_days), 2)          AS max_recovery_days
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY virus_strain
ORDER BY avg_recovery_days DESC;

-- -------------------------------------------------------
-- Q5.  Which age group has the highest hospitalisation rate?
-- -------------------------------------------------------
SELECT
    age_group,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN hospitalization = 'Yes' THEN 1 ELSE 0 END)             AS hospitalised,
    ROUND(
        SUM(CASE WHEN hospitalization = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS hospitalisation_rate_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY age_group
ORDER BY hospitalisation_rate_pct DESC;

-- -------------------------------------------------------
-- Q6.  Does gender influence fatality outcomes?
-- -------------------------------------------------------
SELECT
    gender,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS deaths,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY gender;

-- -------------------------------------------------------
-- Q7.  How does season affect case volume and recovery time?
-- -------------------------------------------------------
SELECT
    season,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS deaths,
    ROUND(AVG(recovery_days), 2)                                         AS avg_recovery_days
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY season
ORDER BY total_cases DESC;

-- -------------------------------------------------------
-- Q8.  Which exposure source leads to the most deaths?
-- -------------------------------------------------------
SELECT
    exposure_source,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS total_deaths,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY exposure_source
ORDER BY total_deaths DESC;

-- -------------------------------------------------------
-- Q9.  Do high-risk environments (high rodent index +
--      high humidity) increase fatality and recovery time?
-- -------------------------------------------------------
SELECT
    high_risk_env,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS deaths,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct,
    ROUND(AVG(recovery_days), 2)                                         AS avg_recovery_days
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY high_risk_env;

-- -------------------------------------------------------
-- Q10. Do countries with longer quarantine periods show
--      lower fatality rates?
-- -------------------------------------------------------
SELECT
    country,
    ROUND(AVG(quarantine_days), 2)                                       AS avg_quarantine_days,
    COUNT(*)                                                              AS total_cases,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY country
ORDER BY avg_quarantine_days DESC;

-- -------------------------------------------------------
-- Q11. What is the monthly trend in new cases and deaths?
-- -------------------------------------------------------
SELECT
    DATE_FORMAT(report_date, '%Y-%m')                                    AS report_month,
    COUNT(*)                                                              AS new_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS deaths
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY report_month
ORDER BY report_month;

-- -------------------------------------------------------
-- Q12. How does population density relate to
--      transmission type distribution?
-- -------------------------------------------------------
SELECT
    CASE
        WHEN population_density <  1000 THEN 'Low  (< 1000)'
        WHEN population_density <  5000 THEN 'Medium (1000–4999)'
        ELSE                                 'High (5000+)'
    END                                                                   AS density_group,
    transmission_type,
    COUNT(*)                                                              AS total_cases
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY density_group, transmission_type
ORDER BY density_group, total_cases DESC;

-- -------------------------------------------------------
-- Q13. Which virus strain is dominant in each country?
-- -------------------------------------------------------
SELECT
    country,
    virus_strain,
    COUNT(*) AS case_count
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY country, virus_strain
HAVING case_count = (
    SELECT MAX(inner_count)
    FROM (
        SELECT country AS c, COUNT(*) AS inner_count
        FROM global_hantavirus_surveillance_dataset_2026
        WHERE country = global_hantavirus_surveillance_dataset_2026.country
        GROUP BY virus_strain
    ) AS sub
)
ORDER BY country;

-- -------------------------------------------------------
-- Q14. Does Air Quality Index (AQI) affect recovery time
--      and fatality rate?
-- -------------------------------------------------------
SELECT
    CASE
        WHEN air_quality_index <  50  THEN 'Good (0–49)'
        WHEN air_quality_index < 100  THEN 'Moderate (50–99)'
        WHEN air_quality_index < 150  THEN 'Unhealthy Sensitive (100–149)'
        ELSE                               'Unhealthy (150+)'
    END                                                                   AS aqi_category,
    COUNT(*)                                                              AS total_cases,
    ROUND(AVG(recovery_days), 2)                                         AS avg_recovery_days,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY aqi_category
ORDER BY avg_recovery_days DESC;

-- -------------------------------------------------------
-- Q15. What are the top 5 highest-risk case profiles?
--      (country + virus strain + transmission type)
-- -------------------------------------------------------
SELECT
    country,
    virus_strain,
    transmission_type,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS deaths,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct,
    ROUND(AVG(recovery_days), 2)                                         AS avg_recovery_days
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY country, virus_strain, transmission_type
HAVING total_cases >= 10
ORDER BY fatality_rate_pct DESC
LIMIT 5;


-- ============================================================
-- STEP 6 : SAVE RESULTS AS VIEWS (reusable for dashboards)
-- ============================================================

-- View 1 : Country-level summary
CREATE OR REPLACE VIEW vw_country_summary AS
SELECT
    country,
    COUNT(*)                                                              AS total_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS total_deaths,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct,
    ROUND(AVG(recovery_days), 2)                                         AS avg_recovery_days,
    ROUND(
        SUM(CASE WHEN hospitalization = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS hospitalisation_pct
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY country;

-- View 2 : Virus strain fatality summary
CREATE OR REPLACE VIEW vw_strain_fatality AS
SELECT
    virus_strain,
    COUNT(*)                                                              AS total_cases,
    ROUND(
        SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                     AS fatality_rate_pct,
    ROUND(AVG(recovery_days), 2)                                         AS avg_recovery_days
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY virus_strain;

-- View 3 : Monthly trend
CREATE OR REPLACE VIEW vw_monthly_trend AS
SELECT
    DATE_FORMAT(report_date, '%Y-%m')                                    AS report_month,
    COUNT(*)                                                              AS new_cases,
    SUM(CASE WHEN fatality = 'Yes' THEN 1 ELSE 0 END)                    AS deaths,
    ROUND(AVG(recovery_days), 2)                                         AS avg_recovery_days
FROM global_hantavirus_surveillance_dataset_2026
GROUP BY report_month
ORDER BY report_month;

-- Verify views
SELECT * FROM vw_country_summary;
SELECT * FROM vw_strain_fatality;
SELECT * FROM vw_monthly_trend;


-- ============================================================
-- END OF PROJECT
-- ============================================================
