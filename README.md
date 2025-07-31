# Automating the Linkage of Open-Access Data

This repository provides an automated codebase for downloading, extracting, and linking open-access datasets. The code was primarily built around the NHS Digital General Practice Workforce dataset and additionally has been tested on the Admitted Patient Care dataset. The code can be adapted and generalised for future use.

## Dataset 1: [General Practice Workforce](https://digital.nhs.uk/data-and-information/publications/statistical/general-and-personal-medical-services)

The General Practice Workforce dataset, published by NHS Digital provides a monthly snapshot of the general practice workforce in England. Each dataset represents the workforce composition as of the last calendar day of the reporting month, including weekends and public holidays:
- September 2015 to September 2017: Collected twice a year, with snapshots on 31 March and 30 September
- September 2017 to July 2021: Collected and published quarterly, with snapshots on 31 March, 30 June, 30 September, and 31 December
- From July 2021 onward: Collection moved to a monthly schedule

The practice level CSV presents the workforce estimates with each record including unique practice identifiers and geographic classifications (Sub-ICB, ICB), along with headcount and Full-Time Equivalent (FTE) measures disaggregated by staff group. These include GPs, categorised by role type (partner, salaried, locum, registrar), nurses, direct patient care staff (clinical pharmacists, physiotherapists), and administrative staff. Workforce counts are further stratified by gender and contract type.

After merging the workforce datasets across all available publication snapshots, the resulting summary table reveals a clear temporal trend in the structure of the data. 
- There is a gradual decrease in the number of rows over time, which likely reflects structural changes in the healthcare system. 
- The number of columns in the dataset shows an increase, suggesting that more variables have been introduced in later years. This indicates a broadening of data collection practices over time, capturing a wider range of workforce characteristics and administrative details.

## Dataset 2: [Hospital Admitted Patient Care Activity](https://digital.nhs.uk/data-and-information/publications/statistical/hospital-admitted-patient-care-activity)

The Hospital Admitted Patient Care Activity dataset, published by NHS Digital, provides yearly snapshots of hospital inpatient episodes in England. Each dataset is grouped according to the responsible commissioning organisation:
- Before July 2022: Grouped by Clinical Commissioning Groups (CCGs)
- From July 2022 onward: Grouped by Integrated Care Boards (ICBs)
The source for this publication is Hospital Episode Statistics (HES), which records information on all inpatient admissions, including diagnostic codes, procedures, and administrative details.
This dataset enables analysis of hospital activity trends and variation at a regional or organisational level over time, and can be linked to other datasets using consistent geographic identifiers.
