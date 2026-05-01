/*
=============================================================================================
HOSPITAL READMISSION DATA CLEANING & EXPLORATION
Author   : Mati Nagari
Database : HospitalDB
Dataset  : Diabetes 130-US Hospitals (1999-2008)
=============================================================================================

EXECUTIVE SUMMARY: 
Analyzed 101,766 diabetic patient records to identify drivers of 30-day readmissions. 
The analysis pinpointed high-risk patient profiles, specifically those with 9+ diagnoses 
and fluctuating insulin requirements, to help hospitals prioritize discharge planning.

BUSINESS PROBLEM: 
Hospital readmissions are a critical quality metric. High return rates lead to 
financial penalties and poor patient outcomes. This project provides a structured 
data layer to identify high-risk patients and reduce preventable returns.

RECOMMENDATIONS: 
1. Implement "Complexity Flags" for patients with 9+ concurrent diagnoses.
2. Prioritize follow-up care for patients requiring insulin dosage adjustments during stay.
3. Focus resource allocation on Cardiology and Emergency departments for discharge support.

SKILLS DEMONSTRATED:
    - Data Cleaning & ETL
    - CTEs (Common Table Expressions)
    - Temp Tables
    - Window Functions
    - Aggregate Functions
    - CASE Statements
    - Creating Views
    - Converting Data Types
    - NULLIF for Safe Division
=============================================================================================
*/

-- =============================================================
--  PART 1 — DATA CLEANING
-- =============================================================


-- Replace '?' with NULL across all affected columns

UPDATE HospitalDB.dbo.DiabetesReadmission SET race             = NULL WHERE race             = '?';
UPDATE HospitalDB.dbo.DiabetesReadmission SET gender           = NULL WHERE gender           = '?';
UPDATE HospitalDB.dbo.DiabetesReadmission SET weight           = NULL WHERE weight           = '?';
UPDATE HospitalDB.dbo.DiabetesReadmission SET payer_code       = NULL WHERE payer_code       = '?';
UPDATE HospitalDB.dbo.DiabetesReadmission SET medical_specialty= NULL WHERE medical_specialty= '?';
UPDATE HospitalDB.dbo.DiabetesReadmission SET diag_1           = NULL WHERE diag_1           = '?';
UPDATE HospitalDB.dbo.DiabetesReadmission SET diag_2           = NULL WHERE diag_2           = '?';
UPDATE HospitalDB.dbo.DiabetesReadmission SET diag_3           = NULL WHERE diag_3           = '?';


-- Drop irrelevant columns
-- weight: 96% NULL | payer_code: 39% NULL

ALTER TABLE HospitalDB.dbo.DiabetesReadmission DROP COLUMN weight;
ALTER TABLE HospitalDB.dbo.DiabetesReadmission DROP COLUMN payer_code;


-- Remove duplicate patient records — keep first encounter only

WITH RankedEncounters AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY patient_nbr
            ORDER BY encounter_id
        ) AS RowNum
    FROM HospitalDB.dbo.DiabetesReadmission
)
DELETE FROM RankedEncounters
WHERE RowNum > 1;


-- Remove invalid gender entry

DELETE FROM HospitalDB.dbo.DiabetesReadmission
WHERE gender = 'Unknown/Invalid';


-- Standardize readmitted column to readable labels

UPDATE HospitalDB.dbo.DiabetesReadmission
SET readmitted = CASE
    WHEN readmitted = 'NO'  THEN 'Not Readmitted'
    WHEN readmitted = '>30' THEN 'Readmitted After 30 Days'
    WHEN readmitted = '<30' THEN 'Readmitted Within 30 Days'
    ELSE readmitted
END;


-- Add numeric age midpoint column for easier analysis

ALTER TABLE HospitalDB.dbo.DiabetesReadmission
ADD AgeMidpoint INT;

UPDATE HospitalDB.dbo.DiabetesReadmission
SET AgeMidpoint = CASE
    WHEN age = '[0-10)'   THEN 5
    WHEN age = '[10-20)'  THEN 15
    WHEN age = '[20-30)'  THEN 25
    WHEN age = '[30-40)'  THEN 35
    WHEN age = '[40-50)'  THEN 45
    WHEN age = '[50-60)'  THEN 55
    WHEN age = '[60-70)'  THEN 65
    WHEN age = '[70-80)'  THEN 75
    WHEN age = '[80-90)'  THEN 85
    WHEN age = '[90-100)' THEN 95
    ELSE NULL
END;


-- =============================================================
--  PART 2 — DATA EXPLORATION
-- =============================================================


-- 1. Overall Readmission Rate

SELECT
    readmitted,
    COUNT(*)                                                        AS PatientCount,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS Percentage
FROM HospitalDB.dbo.DiabetesReadmission
GROUP BY readmitted
ORDER BY PatientCount DESC;


-- 2. Readmission Rate by Age Group

SELECT
    age                                           AS AgeGroup,
    AgeMidpoint,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM HospitalDB.dbo.DiabetesReadmission
GROUP BY age, AgeMidpoint
ORDER BY AgeMidpoint;


-- 3. Readmission Rate by Gender

SELECT
    gender,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM HospitalDB.dbo.DiabetesReadmission
WHERE gender IS NOT NULL
GROUP BY gender
ORDER BY ReadmissionRate_Pct DESC;


-- 4. Readmission Rate by Race

SELECT
    race,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM HospitalDB.dbo.DiabetesReadmission
WHERE race IS NOT NULL
GROUP BY race
ORDER BY ReadmissionRate_Pct DESC;


-- 5. Top Medical Specialties with Highest Readmission Rates

SELECT TOP 15
    medical_specialty,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM HospitalDB.dbo.DiabetesReadmission
WHERE medical_specialty IS NOT NULL
GROUP BY medical_specialty
HAVING COUNT(*) > 100
ORDER BY ReadmissionRate_Pct DESC;


-- 6. Impact of Time in Hospital on Readmission

SELECT
    time_in_hospital                              AS DaysInHospital,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM HospitalDB.dbo.DiabetesReadmission
GROUP BY time_in_hospital
ORDER BY time_in_hospital;


-- 7. Impact of Number of Diagnoses on Readmission

SELECT
    number_diagnoses                              AS NumberOfDiagnoses,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM HospitalDB.dbo.DiabetesReadmission
GROUP BY number_diagnoses
ORDER BY number_diagnoses;


-- 8. Impact of Number of Medications on Readmission — CTE

WITH MedicationGroups AS (
    SELECT *,
        CASE
            WHEN num_medications BETWEEN 1  AND 10 THEN '1-10 Medications'
            WHEN num_medications BETWEEN 11 AND 20 THEN '11-20 Medications'
            WHEN num_medications BETWEEN 21 AND 30 THEN '21-30 Medications'
            WHEN num_medications > 30              THEN '30+ Medications'
            ELSE 'Unknown'
        END AS MedicationGroup
    FROM HospitalDB.dbo.DiabetesReadmission
)
SELECT
    MedicationGroup,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM MedicationGroups
GROUP BY MedicationGroup
ORDER BY MedicationGroup;


-- 9. Impact of Lab Procedures on Readmission — CTE

WITH LabGroups AS (
    SELECT *,
        CASE
            WHEN num_lab_procedures BETWEEN 1  AND 20 THEN '1-20 Labs'
            WHEN num_lab_procedures BETWEEN 21 AND 40 THEN '21-40 Labs'
            WHEN num_lab_procedures BETWEEN 41 AND 60 THEN '41-60 Labs'
            WHEN num_lab_procedures > 60               THEN '60+ Labs'
            ELSE 'Unknown'
        END AS LabGroup
    FROM HospitalDB.dbo.DiabetesReadmission
)
SELECT
    LabGroup,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM LabGroups
GROUP BY LabGroup
ORDER BY LabGroup;


-- 10. Most Common Primary Diagnoses Among Readmitted Patients

SELECT TOP 15
    diag_1                                        AS PrimaryDiagnosis,
    COUNT(*)                                      AS TotalReadmitted
FROM HospitalDB.dbo.DiabetesReadmission
WHERE readmitted = 'Readmitted Within 30 Days'
  AND diag_1 IS NOT NULL
GROUP BY diag_1
ORDER BY TotalReadmitted DESC;


-- 11. Insulin Usage and Readmission

SELECT
    insulin,
    COUNT(*)                                      AS TotalPatients,
    SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30,
    CAST(SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))    AS ReadmissionRate_Pct
FROM HospitalDB.dbo.DiabetesReadmission
GROUP BY insulin
ORDER BY ReadmissionRate_Pct DESC;


-- 12. Rolling Readmission Count by Hospital Stay Length — Window Function

WITH ReadmissionByStay AS (
    SELECT
        time_in_hospital                          AS DaysInHospital,
        COUNT(*)                                  AS TotalPatients,
        SUM(CASE WHEN readmitted = 'Readmitted Within 30 Days' THEN 1 ELSE 0 END) AS ReadmittedWithin30
    FROM HospitalDB.dbo.DiabetesReadmission
    GROUP BY time_in_hospital
)
SELECT
    DaysInHospital,
    TotalPatients,
    ReadmittedWithin30,
    SUM(ReadmittedWithin30) OVER (ORDER BY DaysInHospital) AS RollingReadmissionTotal,
    CAST(ReadmittedWithin30 * 100.0
        / NULLIF(TotalPatients, 0) AS DECIMAL(5,2)) AS ReadmissionRate_Pct
FROM ReadmissionByStay
ORDER BY DaysInHospital;


-- 13. Create View for Tableau / Power BI Visualization

CREATE OR ALTER VIEW vw_ReadmissionSummary AS
SELECT
    encounter_id,
    patient_nbr,
    race,
    gender,
    age,
    AgeMidpoint,
    time_in_hospital,
    num_lab_procedures,
    num_procedures,
    num_medications,
    number_diagnoses,
    number_outpatient,
    number_emergency,
    number_inpatient,
    medical_specialty,
    insulin,
    diabetesMed,
    diag_1,
    readmitted,
    CASE
        WHEN readmitted = 'Readmitted Within 30 Days' THEN 1
        ELSE 0
    END AS ReadmittedFlag
FROM HospitalDB.dbo.DiabetesReadmission;
