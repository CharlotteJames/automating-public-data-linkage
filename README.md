# automating-public-data-linkage

This repository provides an automated codebase for downloading, extracting, and linking open-access datasets. The code was primarily built around the NHS Digital General Practice Workforce dataset and additionally has been tested on the Admitted Patient Care dataset. The code can be adapted and generalised for future use. 
 
### Dataset 
 
The General Practice Workforce dataset, published by NHS Digital provides a monthly snapshot of the general practice workforce in England. Each dataset represents the workforce composition as of the last calendar day of the reporting month, including weekends and public holidays. Prior to July 2021, data was collected and published quarterly, with snapshots recorded on 31 March, 30 June, 30 September, and 31 December, and then transitioned to monthly data collection and publication from July 2021 onward. 
 
The practice level CSV presents the workforce estimates with each record including unique practice identifiers and geographic classifications (Sub-ICB, ICB), along with headcount and Full-Time Equivalent (FTE) measures disaggregated by staff group. These include GPs, categorised by role type (partner, salaried, locum, registrar), nurses, direct patient care staff (clinical pharmacists, physiotherapists), and administrative staff. Workforce counts are further stratified by gender and contract type. 
 
After merging the workforce datasets across all available publication snapshots, the resulting summary table reveals a clear temporal trend in the structure of the data.  
- There is a gradual decrease in the number of rows over time, which likely reflects structural changes in the healthcare system.
- The number of columns in the dataset shows an increase, suggesting that more variables have been introduced in later years. This indicates a broadening of data collection practices over time, capturing a wider range of workforce characteristics and administrative details. 
