# PIM Role Assignments — Grouped by Project (Security Group View)
**User:** rennielf-admin@melbwater.onmicrosoft.com  
**Prepared:** 2026-06-04  
**Purpose:** PIM eligible role assignments organised by project for Entra ID security group creation and renewal management

> ⚠️ **OVERDUE:** Role #1 (Support Request Contributor on `1.MelbWater-PRD`) expired **2026-06-02** — raise ServiceNow request immediately.

---

## Summary

| Project | Security Group | Environments | Roles | Role Count | Next Expiry |
|---------|---------------|--------------|-------|------------|-------------|
| AIS | `sg-pim-ais` | PRD-AE, PRD-ASE, UAT | Data Factory Contributor | 3 | 2026-06-30 |
| PEGA | `sg-pim-pega` | PRD-AE | Key Vault Certificates Officer<br>Key Vault Crypto Officer<br>Key Vault Secrets Officer<br>Logic App Contributor<br>Storage Blob Data Contributor<br>Storage File Data Privileged Contributor<br>Storage Queue Data Contributor<br>Storage Table Data Contributor<br>Website Contributor | 9 | 2026-06-30 |
| POL | `sg-pim-pol` | DEV/TEST, PRD-AE, PRD-ASE, UAT | Key Vault Certificates Officer<br>Key Vault Crypto Officer<br>Key Vault Secrets Officer<br>Logic App Contributor<br>Storage Blob Data Contributor<br>Storage File Data Privileged Contributor<br>Storage Queue Data Contributor<br>Storage Table Data Contributor<br>Website Contributor | 36 | 2026-06-30 |
| SENTINEL | `sg-pim-sentinel` | DEV/TEST, PRD-ASE | Key Vault Certificates Officer<br>Key Vault Crypto Officer<br>Key Vault Secrets Officer<br>Logic App Contributor<br>Storage Blob Data Contributor<br>Storage File Data Privileged Contributor<br>Storage Queue Data Contributor<br>Storage Table Data Contributor<br>Website Contributor | 18 | 2026-06-30 |
| MWDL | `sg-pim-mwdl` | PRD-ASE (env 01 & 02) | Data Factory Contributor<br>Key Vault Crypto Officer<br>Key Vault Secrets Officer<br>Logic App Contributor<br>Storage Blob Data Reader<br>Website Contributor | 10 | 2026-06-30 |
| (Subscription) | — | 1.MelbWater-PRD | Support Request Contributor | 1 | ~~2026-06-02~~ **EXPIRED** |
| (Mgmt Group) | — | PIM-v1-MG | PIM_AzReader | 1 | 2026-06-20 |

---

## AIS — Azure Integration Services
**Security Group:** `sg-pim-ais`  
**Resource Groups:** `rg-prd-ae-ais` · `rg-prd-ase-ais` · `rg-uat-ase-ais`

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Data Factory Contributor | rg-prd-ae-ais | PRD-AE | 2026-06-30 |
| 2 | Data Factory Contributor | rg-prd-ase-ais | PRD-ASE | 2026-06-30 |
| 3 | Data Factory Contributor | rg-uat-ase-ais | UAT | 2026-06-30 |

---

## PEGA — Pega Platform
**Security Group:** `sg-pim-pega`  
**Resource Groups:** `rg-prd-ae-pega`

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
**Security Group:** `sg-pim-pol`  
**Resource Groups:** `rg-devtest-ase-pol` · `rg-prd-ae-pol` · `rg-prd-ase-pol` · `rg-uat-ase-pol`

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Key Vault Certificates Officer | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 2 | Key Vault Certificates Officer | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 3 | Key Vault Certificates Officer | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 4 | Key Vault Certificates Officer | rg-uat-ase-pol | UAT | 2026-06-30 |
| 5 | Key Vault Crypto Officer | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 6 | Key Vault Crypto Officer | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 7 | Key Vault Crypto Officer | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 8 | Key Vault Crypto Officer | rg-uat-ase-pol | UAT | 2026-06-30 |
| 9 | Key Vault Secrets Officer | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 10 | Key Vault Secrets Officer | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 11 | Key Vault Secrets Officer | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 12 | Key Vault Secrets Officer | rg-uat-ase-pol | UAT | 2026-06-30 |
| 13 | Logic App Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 14 | Logic App Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 15 | Logic App Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 16 | Logic App Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 17 | Storage Blob Data Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 18 | Storage Blob Data Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 19 | Storage Blob Data Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 20 | Storage Blob Data Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 21 | Storage File Data Privileged Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 22 | Storage File Data Privileged Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 23 | Storage File Data Privileged Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 24 | Storage File Data Privileged Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 25 | Storage Queue Data Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 26 | Storage Queue Data Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 27 | Storage Queue Data Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 28 | Storage Queue Data Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 29 | Storage Table Data Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 30 | Storage Table Data Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 31 | Storage Table Data Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 32 | Storage Table Data Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |
| 33 | Website Contributor | rg-devtest-ase-pol | DEV/TEST | 2026-06-30 |
| 34 | Website Contributor | rg-prd-ae-pol | PRD-AE | 2026-06-30 |
| 35 | Website Contributor | rg-prd-ase-pol | PRD-ASE | 2026-06-30 |
| 36 | Website Contributor | rg-uat-ase-pol | UAT | 2026-06-30 |

---

## SENTINEL
**Security Group:** `sg-pim-sentinel`  
**Resource Groups:** `rg-devtest-ase-sentinel` · `rg-prd-ase-sentinel`

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Key Vault Certificates Officer | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 2 | Key Vault Certificates Officer | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 3 | Key Vault Crypto Officer | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 4 | Key Vault Crypto Officer | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 5 | Key Vault Secrets Officer | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 6 | Key Vault Secrets Officer | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 7 | Logic App Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 8 | Logic App Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 9 | Storage Blob Data Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 10 | Storage Blob Data Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 11 | Storage File Data Privileged Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 12 | Storage File Data Privileged Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 13 | Storage Queue Data Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 14 | Storage Queue Data Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 15 | Storage Table Data Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 16 | Storage Table Data Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |
| 17 | Website Contributor | rg-devtest-ase-sentinel | DEV/TEST | 2026-06-30 |
| 18 | Website Contributor | rg-prd-ase-sentinel | PRD-ASE | 2026-06-30 |

---

## MWDL — MelbWater Data Lake
**Security Group:** `sg-pim-mwdl`  
**Resource Groups:** `rg-prod-ase-mwdl-01` · `rg-prod-ase-mwdl-02`

| # | Role | Resource Group | Environment | Expires On |
|---|------|----------------|-------------|------------|
| 1 | Data Factory Contributor | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 2 | Key Vault Crypto Officer | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 3 | Key Vault Secrets Officer | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 4 | Key Vault Secrets Officer | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 5 | Logic App Contributor | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 6 | Logic App Contributor | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 7 | Storage Blob Data Reader | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 8 | Storage Blob Data Reader | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |
| 9 | Website Contributor | rg-prod-ase-mwdl-01 | PRD-ASE (env 01) | 2026-06-30 |
| 10 | Website Contributor | rg-prod-ase-mwdl-02 | PRD-ASE (env 02) | 2026-06-30 |

---

## Other Scopes — Subscription / Management Group
> These roles are scoped above resource group level and are not project-specific. Manage renewals individually.

| # | Role | Scope | Scope Type | Expires On | Status |
|---|------|-------|------------|------------|--------|
| 1 | Support Request Contributor | 1.MelbWater-PRD | Subscription | 2026-06-02 | ⚠️ EXPIRED — raise ServiceNow immediately |
| 2 | PIM_AzReader | PIM-v1-MG | Management Group | 2026-06-20 | Raise ServiceNow this week |

---

## Renewal Quick Reference

| Project | Security Group | Expiry | Action Required |
|---------|---------------|--------|-----------------|
| AIS | `sg-pim-ais` | 2026-06-30 | Raise ServiceNow by end of June |
| PEGA | `sg-pim-pega` | 2026-06-30 | Raise ServiceNow by end of June |
| POL | `sg-pim-pol` | 2026-06-30 | Raise ServiceNow by end of June |
| SENTINEL | `sg-pim-sentinel` | 2026-06-30 | Raise ServiceNow by end of June |
| MWDL | `sg-pim-mwdl` | 2026-06-30 | Raise ServiceNow by end of June |
| (Subscription) | — | ~~2026-06-02~~ | ⚠️ EXPIRED — act now |
| (Mgmt Group) | — | 2026-06-20 | Raise ServiceNow this week |
