### Hospital Readmission Analysis (SQL)
**Industry:** Healthcare / Health Informatics  
**Target Metric:** 30-Day Readmission Rate

---

## 1. Executive Summary
This project analyzes **101,766 diabetic patient records** from 130 US hospitals to identify high-risk drivers of 30-day readmissions. By cleaning clinical EHR data and utilizing advanced SQL techniques like CTEs and Window Functions, I identified that **diagnosis count** and **insulin stability** are the strongest predictors of patient return. The final output is an optimized SQL View ready for stakeholder reporting and BI dashboarding.

## 2. Business Problem
Hospital readmissions within 30 days are a primary indicator of care quality and a major source of financial penalties under value-based care models. The challenge is identifying high-risk patients *before* they are discharged. This project provides the data layer needed to help clinical teams prioritize follow-up care for the most vulnerable patients.

## 3. Skills
* **SQL (T-SQL):** CTEs, Window Functions, Temp Tables, CASE Statements, NULLIF.
* **ETL & Data Cleaning:** Handling missing values (`?`), deduplication (ROW_NUMBER), and schema optimization.
* **Domain Expertise:** Healthcare Informatics, Patient Risk Stratification.

## 4. Methodology
* **Data Cleaning:** Replaced non-standard markers, dropped high-null columns (90%+ missing), and filtered for the first encounter per patient to ensure data integrity.
* **Exploratory Data Analysis (EDA):** Segmented readmission rates across demographics, clinical intensity (medication counts), and hospital stay length.
* **Visualization Prep:** Created a final **SQL View** with a binary `ReadmittedFlag` for seamless integration with Power BI or Tableau.

## 5. Results
* **The Complexity Spike:** Patients with **9 or more diagnoses** show a significant increase in readmission risk compared to those with simpler clinical profiles.
* **Medication Churn:** Patients whose insulin dosage was adjusted (Up/Down) during their stay had higher return rates than those kept on a steady dosage.
* **Stay Correlation:** Identified a "U-shaped" risk—both premature discharges and exceptionally long stays (10+ days) correlate with higher 30-day return rates.

## 6. Business Recommendations
* **High-Risk Flagging:** Hospitals should implement an automated "Complexity Flag" for any patient with 9+ diagnoses or fluctuating insulin requirements during their stay.
* **Strategic Resource Allocation:** I advise the clinical team to focus discharge resources on the **Cardiology** and **Emergency** departments, as these showed the highest readmission trends.
* **Next Steps:** I recommend conducting an A/B test on a "Post-Discharge Follow-up Program" specifically targeting the 9+ diagnosis patient cohort identified in this analysis.

---
*This project demonstrates my ability to take a massive, unorganized healthcare dataset and extract the story hidden in the numbers to drive better business and clinical decisions.*
