# PIM Expiring Roles — Consolidated by Application
**User:** rennielf-admin@melbwater.onmicrosoft.com  
**Prepared:** 2026-06-04  
**Source:** pim-renewal-june-2026.md  
**Total roles:** 78

> ⚠️ **OVERDUE:** Support Request Contributor on `1.MelbWater-PRD` expired **2026-06-02** — raise ServiceNow immediately.

---

## Summary — Roles by Application and Resource Group

| Application | Resource Group | Role Count | Expires On |
|-------------|---------------|------------|------------|
| AIS | rg-prd-ae-ais | 1 | 2026-06-30 |
| AIS | rg-prd-ase-ais | 1 | 2026-06-30 |
| AIS | rg-uat-ase-ais | 1 | 2026-06-30 |
| **AIS Total** | | **3** | |
| MWDL | rg-prod-ase-mwdl-01 | 4 | 2026-06-30 |
| MWDL | rg-prod-ase-mwdl-02 | 6 | 2026-06-30 |
| **MWDL Total** | | **10** | |
| PEGA | rg-prd-ae-pega | 9 | 2026-06-30 |
| **PEGA Total** | | **9** | |
| POL | rg-devtest-ase-pol | 9 | 2026-06-30 |
| POL | rg-prd-ae-pol | 9 | 2026-06-30 |
| POL | rg-prd-ase-pol | 9 | 2026-06-30 |
| POL | rg-uat-ase-pol | 9 | 2026-06-30 |
| **POL Total** | | **36** | |
| SENTINEL | rg-devtest-ase-sentinel | 9 | 2026-06-30 |
| SENTINEL | rg-prd-ase-sentinel | 9 | 2026-06-30 |
| **SENTINEL Total** | | **18** | |
| *(Subscription)* | 1.MelbWater-PRD | 1 | ~~2026-06-02~~ ⚠️ EXPIRED |
| *(Mgmt Group)* | PIM-v1-MG | 1 | 2026-06-20 |
| **Grand Total** | | **78** | |

---

## AIS — Azure Integration Services

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Data Factory Contributor | rg-prd-ae-ais | PRD-AE | 2026-06-30 |
| 2 | Data Factory Contributor | rg-prd-ase-ais | PRD-ASE | 2026-06-30 |
| 3 | Data Factory Contributor | rg-uat-ase-ais | UAT | 2026-06-30 |

---

## MWDL — MelbWater Data Lake

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Key Vault Secrets Officer | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 2 | Logic App Contributor | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 3 | Storage Blob Data Reader | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 4 | Website Contributor | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 5 | Data Factory Contributor | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 6 | Key Vault Crypto Officer | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 7 | Key Vault Secrets Officer | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 8 | Logic App Contributor | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 9 | Storage Blob Data Reader | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 10 | Website Contributor | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |

---

## PEGA — Pega Platform

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Key Vault Certificates Officer | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 2 | Key Vault Crypto Officer | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 3 | Key Vault Secrets Officer | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 4 | Logic App Contributor | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 5 | Storage Blob Data Contributor | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 6 | Storage File Data Privileged Contributor | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 7 | Storage Queue Data Contributor | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 8 | Storage Table Data Contributor | rg-prd-ae-pega | PRD-AE | 2026-06-30 |
| 9 | Website Contributor | rg-prd-ae-pega | PRD-AE | 2026-06-30 |

---

## POL — Policy Services

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Key Vault Certificates Officer | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 2 | Key Vault Crypto Officer | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 3 | Key Vault Secrets Officer | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 4 | Logic App Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 5 | Storage Blob Data Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 6 | Storage File Data Privileged Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 7 | Storage Queue Data Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 8 | Storage Table Data Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 9 | Website Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 10 | Key Vault Certificates Officer | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 11 | Key Vault Crypto Officer | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 12 | Key Vault Secrets Officer | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 13 | Logic App Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 14 | Storage Blob Data Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 15 | Storage File Data Privileged Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 16 | Storage Queue Data Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 17 | Storage Table Data Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 18 | Website Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 19 | Key Vault Certificates Officer | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 20 | Key Vault Crypto Officer | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 21 | Key Vault Secrets Officer | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 22 | Logic App Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 23 | Storage Blob Data Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 24 | Storage File Data Privileged Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 25 | Storage Queue Data Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 26 | Storage Table Data Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 27 | Website Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 28 | Key Vault Certificates Officer | rg-uat-ase-pol | UAT | 2026-06-30 |
| 29 | Key Vault Crypto Officer | rg-uat-ase-pol | UAT | 2026-06-30 |
| 30 | Key Vault Secrets Officer | rg-uat-ase-pol | UAT | 2026-06-30 |
| 31 | Logic App Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 32 | Storage Blob Data Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 33 | Storage File Data Privileged Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 34 | Storage Queue Data Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 35 | Storage Table Data Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 36 | Website Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |

---

## SENTINEL

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Key Vault Certificates Officer | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 2 | Key Vault Crypto Officer | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 3 | Key Vault Secrets Officer | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 4 | Logic App Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 5 | Storage Blob Data Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 6 | Storage File Data Privileged Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 7 | Storage Queue Data Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 8 | Storage Table Data Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 9 | Website Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 10 | Key Vault Certificates Officer | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 11 | Key Vault Crypto Officer | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 12 | Key Vault Secrets Officer | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 13 | Logic App Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 14 | Storage Blob Data Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 15 | Storage File Data Privileged Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 16 | Storage Queue Data Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 17 | Storage Table Data Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 18 | Website Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |

---

## Other Scopes

| # | Role | Scope | Scope Type | Expires On |
|---|------|-------|------------|------------|
| 1 | Support Request Contributor | 1.MelbWater-PRD | Subscription | ~~2026-06-02~~ ⚠️ EXPIRED |
| 2 | PIM_AzReader | PIM-v1-MG | Management Group | 2026-06-20 |
