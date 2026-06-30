# WTP Birdwatching Azure Infrastructure

This repository contains Bicep infrastructure-as-code templates for deploying the core Azure resources for the WTP Birdwatching application across multiple environments. The structure and patterns mirror the `pol-azure-infra` repository (Azure Verified Modules, per-resource build/deploy pipelines, environment-scoped `*.common.bicep` config).

> **Action required before first deployment:** Replace all `REPLACE-WITH-*` placeholders in `dev.common.bicep`, `uat.common.bicep`, and `prd.common.bicep` (subscription IDs, cost centre, app registration client ID).

## Infrastructure Resources

| Environment | Resource Type | Resource Name | Resource Group | Parameter File |
|------------|--------------|---------------|----------------|----------------|
| **DEV** | Managed Identity | `mi-devtest-ase-bw` | `rg-devtest-ase-bw` | `dev-mi.bicepparam` |
| DEV | Key Vault | `kv-devtest-ase-bw` | `rg-devtest-ase-bw` | `dev-kv.bicepparam` |
| DEV | Storage Account | `stdevtestasebw` | `rg-devtest-ase-bw` | `dev-sa.bicepparam` |
| DEV | Notification Hubs Namespace | `ntfns-devtest-ase-bw` | `rg-devtest-ase-bw` | `dev-nh.bicepparam` |
| **UAT** | Managed Identity | `mi-uat-ase-bw` | `rg-uat-ase-bw` | `uat-mi.bicepparam` |
| UAT | Key Vault | `kv-uat-ase-bw` | `rg-uat-ase-bw` | `uat-kv.bicepparam` |
| UAT | Storage Account | `stuatasebw` | `rg-uat-ase-bw` | `uat-sa.bicepparam` |
| UAT | Notification Hubs Namespace | `ntfns-uat-ase-bw` | `rg-uat-ase-bw` | `uat-nh.bicepparam` |
| **PRD** | Managed Identity | `mi-prd-ase-bw` | `rg-prd-ase-bw` | `prd-mi.bicepparam` |
| PRD | Key Vault | `kv-prd-ase-bw` | `rg-prd-ase-bw` | `prd-kv.bicepparam` |
| PRD | Storage Account | `stprdasebw` | `rg-prd-ase-bw` | `prd-sa.bicepparam` |
| PRD | Notification Hubs Namespace | `ntfns-prd-ase-bw` | `rg-prd-ase-bw` | `prd-nh.bicepparam` |

### Key Configuration Details

#### DEV Environment (devtest)
- **Location**: Australia Southeast
- **Resource Group**: `rg-devtest-ase-bw`
- **Key Vault**: Soft Delete 7 days, Purge Protection Enabled, RBAC, private endpoint only
- **Storage**: Standard_LRS with Customer-Managed Encryption, private endpoints
- **Notification Hubs**: Free SKU
- **Diagnostics**: `la-hub-ae-sentinel-test` in `rg-hub-ae-sentinel`

#### UAT Environment
- **Location**: Australia Southeast
- **Resource Group**: `rg-uat-ase-bw`
- **Key Vault**: Soft Delete 90 days, Purge Protection Enabled, RBAC, private endpoint only
- **Storage**: Standard_LRS with Customer-Managed Encryption, private endpoints
- **Notification Hubs**: Standard SKU
- **Diagnostics**: `la-hub-ae-sentinel` in `rg-hub-ae-sentinel`

#### PRD Environment (Production)
- **Location**: Australia Southeast
- **Resource Group**: `rg-prd-ase-bw`
- **Key Vault**: Soft Delete 90 days, Purge Protection Enabled, RBAC, private endpoint only
- **Storage**: Standard_GRS with Customer-Managed Encryption, private endpoints
- **Notification Hubs**: Standard SKU
- **Diagnostics**: `la-hub-ae-sentinel` in `rg-hub-ae-sentinel`
- **Enhanced Tags**: Criticality Level, Data Classification, Backup/Monitoring flags

### Diagnostics Routing

| Environment | Log Analytics / Sentinel Workspace | Resource Group |
|-------------|------------------------------------|----------------|
| DEV (devtest) | `la-hub-ae-sentinel-test` | `rg-hub-ae-sentinel` |
| UAT | `la-hub-ae-sentinel` | `rg-hub-ae-sentinel` |
| PRD | `la-hub-ae-sentinel` | `rg-hub-ae-sentinel` |

All workspaces live in the hub subscription (`63656dd5-d2aa-4c65-9b6b-5329dd6620af`).

## Deployment Order (Dependencies)

1. **Managed Identities** (`managedidentities/`) — required first for RBAC and CMK access
2. **Key Vaults** (`keyvaults/`) — provides the customer-managed encryption key (`storage-encryption-key`)
3. **Storage Accounts** (`storageaccounts/`) — uses the managed identity + Key Vault key for CMK
4. **Notification Hubs** (`notificationhubs/`) — independent; can deploy any time after the managed identity

## Repository Structure

```
.
├── managedidentities/    # User-assigned managed identity
├── keyvaults/            # Key Vault (RBAC, CMK key, private endpoint)
├── storageaccounts/      # Storage account (CMK, private endpoints)
├── notificationhubs/     # Notification Hubs namespace + hub
├── dev.common.bicep      # DEV environment common config
├── uat.common.bicep      # UAT environment common config
└── prd.common.bicep      # PRD environment common config
```

Each module folder contains:
- `infra-<x>.bicep` — the AVM-based module
- `parameters/<env>-<x>.bicepparam` — per-environment parameters
- `pipeline-bw<x>-build.yml` — build/validation pipeline
- `pipeline-bw<x>-deploy.yml` — multi-stage deploy pipeline (Dev → UAT → Prod)
- `ps-rule.yaml` — PSRule suppressions/config (where applicable)

## Pipelines

Build and deploy pipelines extend the shared `ais/ci-cd-patterns` templates (tag `2.2.0`) and use the `BW/bw-build` and `BW/bw` artifact feeds with `azure.devtest-BW`, `azure.uat-BW`, and `azure.prd-BW` service connections.
