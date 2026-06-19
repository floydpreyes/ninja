# PIM Role Renewal — ServiceNow Request
**User:** rennielf-admin@melbwater.onmicrosoft.com  
**Prepared:** 2026-05-20  
**Purpose:** Renewal of expiring PIM eligible role assignments requiring ServiceNow justification  
**Total roles:** 78

---

## Roles Expiring 2 June 2026 (12 days)

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 1 | Support Request Contributor | 1.MelbWater-PRD | Subscription | 2026-06-02 | Required to raise and manage Azure support requests on behalf of the MelbWater PRD subscription for production incident triage and vendor escalations. |

---

## Roles Expiring 20 June 2026 (31 days)

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 2 | PIM_AzReader | PIM-v1-MG | Management Group | 2026-06-20 | Read access across the PIM-v1 management group is required to audit and validate PIM role assignments, policy compliance, and resource configurations. |

---

## Roles Expiring 30 June 2026 (41 days)

### Data Factory

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 3 | Data Factory Contributor | rg-prd-ae-ais | Resource Group | 2026-06-30 | Required to manage ADF pipelines and triggers in the PRD AE integration services resource group for data ingestion and ETL operations. |
| 4 | Data Factory Contributor | rg-prd-ase-ais | Resource Group | 2026-06-30 | Required to manage ADF pipelines and triggers in the PRD ASE integration services resource group for data ingestion and ETL operations. |
| 5 | Data Factory Contributor | rg-prod-ase-mwdl-02 | Resource Group | 2026-06-30 | Required to manage ADF pipelines in the MelbWater Data Lake (MWDL) PRD environment for data lake ingestion workflows. |
| 6 | Data Factory Contributor | rg-uat-ase-ais | Resource Group | 2026-06-30 | Required to manage ADF pipelines and triggers in the UAT integration services resource group for pre-production testing and validation. |

### Key Vault — Certificates Officer

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 7 | Key Vault Certificates Officer | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to manage TLS/SSL certificates used by Policy services in the DEV/TEST environment. |
| 8 | Key Vault Certificates Officer | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to manage certificates used by Sentinel resources in the DEV/TEST environment. |
| 9 | Key Vault Certificates Officer | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to manage TLS/SSL certificates used by Pega platform services in PRD AE. |
| 10 | Key Vault Certificates Officer | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to manage TLS/SSL certificates used by Policy services in PRD AE. |
| 11 | Key Vault Certificates Officer | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to manage TLS/SSL certificates used by Policy services in PRD ASE. |
| 12 | Key Vault Certificates Officer | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to manage certificates used by Sentinel resources in PRD ASE. |
| 13 | Key Vault Certificates Officer | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to manage TLS/SSL certificates used by Policy services in UAT ASE. |

### Key Vault — Crypto Officer

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 14 | Key Vault Crypto Officer | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to manage encryption keys for Policy services in DEV/TEST. |
| 15 | Key Vault Crypto Officer | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to manage encryption keys for Sentinel resources in DEV/TEST. |
| 16 | Key Vault Crypto Officer | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to manage encryption keys for Pega platform services in PRD AE. |
| 17 | Key Vault Crypto Officer | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to manage encryption keys for Policy services in PRD AE. |
| 18 | Key Vault Crypto Officer | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to manage encryption keys for Policy services in PRD ASE. |
| 19 | Key Vault Crypto Officer | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to manage encryption keys for Sentinel resources in PRD ASE. |
| 20 | Key Vault Crypto Officer | rg-prod-ase-mwdl-02 | Resource Group | 2026-06-30 | Required to manage encryption keys for MelbWater Data Lake PRD resources. |
| 21 | Key Vault Crypto Officer | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to manage encryption keys for Policy services in UAT ASE. |

### Key Vault — Secrets Officer

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 22 | Key Vault Secrets Officer | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to read and manage secrets (connection strings, API keys) for Policy services in DEV/TEST. |
| 23 | Key Vault Secrets Officer | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to read and manage secrets for Sentinel resources in DEV/TEST. |
| 24 | Key Vault Secrets Officer | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to read and manage secrets for Pega platform services in PRD AE. |
| 25 | Key Vault Secrets Officer | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to read and manage secrets for Policy services in PRD AE. |
| 26 | Key Vault Secrets Officer | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to read and manage secrets for Policy services in PRD ASE. |
| 27 | Key Vault Secrets Officer | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to read and manage secrets for Sentinel resources in PRD ASE. |
| 28 | Key Vault Secrets Officer | rg-prod-ase-mwdl-01 | Resource Group | 2026-06-30 | Required to read and manage secrets for MelbWater Data Lake PRD resources (environment 01). |
| 29 | Key Vault Secrets Officer | rg-prod-ase-mwdl-02 | Resource Group | 2026-06-30 | Required to read and manage secrets for MelbWater Data Lake PRD resources (environment 02). |
| 30 | Key Vault Secrets Officer | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to read and manage secrets for Policy services in UAT ASE. |

### Logic App Contributor

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 31 | Logic App Contributor | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for Policy automation in DEV/TEST. |
| 32 | Logic App Contributor | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for Sentinel automation playbooks in DEV/TEST. |
| 33 | Logic App Contributor | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for Pega integration in PRD AE. |
| 34 | Logic App Contributor | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for Policy automation in PRD AE. |
| 35 | Logic App Contributor | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for Policy automation in PRD ASE. |
| 36 | Logic App Contributor | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to deploy and manage Logic App automation playbooks for Sentinel in PRD ASE. |
| 37 | Logic App Contributor | rg-prod-ase-mwdl-01 | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for MelbWater Data Lake integrations (env 01). |
| 38 | Logic App Contributor | rg-prod-ase-mwdl-02 | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for MelbWater Data Lake integrations (env 02). |
| 39 | Logic App Contributor | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to deploy and manage Logic App workflows for Policy automation in UAT ASE. |

### Storage — Blob Data Contributor

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 40 | Storage Blob Data Contributor | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to read/write blob storage used by Policy services in DEV/TEST. |
| 41 | Storage Blob Data Contributor | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to read/write blob storage used by Sentinel resources in DEV/TEST. |
| 42 | Storage Blob Data Contributor | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to read/write blob storage used by Pega platform services in PRD AE. |
| 43 | Storage Blob Data Contributor | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to read/write blob storage used by Policy services in PRD AE. |
| 44 | Storage Blob Data Contributor | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to read/write blob storage used by Policy services in PRD ASE. |
| 45 | Storage Blob Data Contributor | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to read/write blob storage used by Sentinel resources in PRD ASE. |
| 46 | Storage Blob Data Contributor | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to read/write blob storage used by Policy services in UAT ASE. |

### Storage — Blob Data Reader

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 47 | Storage Blob Data Reader | rg-prod-ase-mwdl-01 | Resource Group | 2026-06-30 | Required to read blob data from MelbWater Data Lake PRD storage for data pipeline operations (env 01). |
| 48 | Storage Blob Data Reader | rg-prod-ase-mwdl-02 | Resource Group | 2026-06-30 | Required to read blob data from MelbWater Data Lake PRD storage for data pipeline operations (env 02). |

### Storage — File Data Privileged Contributor

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 49 | Storage File Data Privileged Contributor | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to manage Azure File Shares used by Policy services in DEV/TEST. |
| 50 | Storage File Data Privileged Contributor | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to manage Azure File Shares used by Sentinel resources in DEV/TEST. |
| 51 | Storage File Data Privileged Contributor | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to manage Azure File Shares used by Pega platform services in PRD AE. |
| 52 | Storage File Data Privileged Contributor | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to manage Azure File Shares used by Policy services in PRD AE. |
| 53 | Storage File Data Privileged Contributor | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to manage Azure File Shares used by Policy services in PRD ASE. |
| 54 | Storage File Data Privileged Contributor | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to manage Azure File Shares used by Sentinel resources in PRD ASE. |
| 55 | Storage File Data Privileged Contributor | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to manage Azure File Shares used by Policy services in UAT ASE. |

### Storage — Queue Data Contributor

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 56 | Storage Queue Data Contributor | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to send/receive messages on storage queues used by Policy services in DEV/TEST. |
| 57 | Storage Queue Data Contributor | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to send/receive messages on storage queues used by Sentinel in DEV/TEST. |
| 58 | Storage Queue Data Contributor | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to send/receive messages on storage queues used by Pega platform in PRD AE. |
| 59 | Storage Queue Data Contributor | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to send/receive messages on storage queues used by Policy services in PRD AE. |
| 60 | Storage Queue Data Contributor | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to send/receive messages on storage queues used by Policy services in PRD ASE. |
| 61 | Storage Queue Data Contributor | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to send/receive messages on storage queues used by Sentinel in PRD ASE. |
| 62 | Storage Queue Data Contributor | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to send/receive messages on storage queues used by Policy services in UAT ASE. |

### Storage — Table Data Contributor

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 63 | Storage Table Data Contributor | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to read/write table storage used by Policy services in DEV/TEST. |
| 64 | Storage Table Data Contributor | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to read/write table storage used by Sentinel resources in DEV/TEST. |
| 65 | Storage Table Data Contributor | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to read/write table storage used by Pega platform in PRD AE. |
| 66 | Storage Table Data Contributor | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to read/write table storage used by Policy services in PRD AE. |
| 67 | Storage Table Data Contributor | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to read/write table storage used by Policy services in PRD ASE. |
| 68 | Storage Table Data Contributor | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to read/write table storage used by Sentinel resources in PRD ASE. |
| 69 | Storage Table Data Contributor | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to read/write table storage used by Policy services in UAT ASE. |

### Website Contributor

| # | Role | Scope | Scope Type | Expires On | Business Justification |
|---|------|-------|------------|------------|------------------------|
| 70 | Website Contributor | rg-devtest-ase-pol | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for Policy services in DEV/TEST. |
| 71 | Website Contributor | rg-devtest-ase-sentinel | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for Sentinel resources in DEV/TEST. |
| 72 | Website Contributor | rg-prd-ae-pega | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for Pega platform services in PRD AE. |
| 73 | Website Contributor | rg-prd-ae-pol | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for Policy services in PRD AE. |
| 74 | Website Contributor | rg-prd-ase-pol | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for Policy services in PRD ASE. |
| 75 | Website Contributor | rg-prd-ase-sentinel | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for Sentinel resources in PRD ASE. |
| 76 | Website Contributor | rg-prod-ase-mwdl-01 | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for MelbWater Data Lake PRD (env 01). |
| 77 | Website Contributor | rg-prod-ase-mwdl-02 | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for MelbWater Data Lake PRD (env 02). |
| 78 | Website Contributor | rg-uat-ase-pol | Resource Group | 2026-06-30 | Required to deploy and manage App Service web apps for Policy services in UAT ASE. |

---

## Summary

| Expiry Date | Count | Urgency |
|-------------|-------|---------|
| 2026-06-02 | 1 | Raise ServiceNow request immediately |
| 2026-06-20 | 1 | Raise ServiceNow request this week |
| 2026-06-30 | 76 | Raise ServiceNow request by end of May |

> **Note:** The Business Justification column contains suggested text — review and amend as required before submitting to ServiceNow.  
> Entra ID directory roles could not be queried (insufficient Graph API permissions on this account) and are not included above.
