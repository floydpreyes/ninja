# WTP Birdwatching App — Infrastructure Cost Comparison

Project: WTP Birdwatching App (2026)

Version 1.0, 26/05/2026

---

## Assumptions

| Item | Value |
|------|-------|
| Region | Australia East |
| Pricing model | Pay-as-you-go (no reserved instances) |
| Traffic profile | Low-to-medium (WTP visitor volumes; no sustained high concurrency) |
| HA model | Minimum production (2 replicas/VMs per API tier) |
| Cloudflare | **Excluded** — edge security cost owned by MW Security team |
| Currency | AUD (all figures in Australian Dollars; approximate — verify against Azure Pricing Calculator) |
| Azure APIM | **Excluded from project costs** — APIM Premium shared AIS infrastructure managed by Cloud Operations team |
| SQL attribution | Full cost attributed to Birdwatcher (dedicated workload) |
| Container Apps | Consumption plan (scale-to-zero); 1 minimum replica per service for 24/7 availability |
| Auth option | Option A includes Identity API compute; Option B (Entra External ID) removes it — see SAD §8.2.1 |

---

## Scenario 1 — VM-Based Architecture

API workloads run on Azure Virtual Machines. No Container Apps. Azure APIM is shared AIS infrastructure funded by Cloud Operations and is available to both scenarios at no project cost.

### Shared AIS-Equivalent Resources

| Resource | Configuration | AUD/month |
|----------|--------------|----------:|
| Azure APIM Premium (1 unit) ² | Cloud Ops funded — reference cost only | ~$4,330 |
| Azure SQL Database S1 | 20 DTU, 250 GB, TDE, private endpoint | ~$47 |
| **Subtotal (project cost — excl. APIM ²)** | | **~$47** |

> ² APIM Premium cost shown for reference only. Funded by Cloud Operations; excluded from all project totals.

### Birdwatcher-Equivalent Resources

| Resource | Configuration | AUD/month |
|----------|--------------|----------:|
| VMs — Operations API | 2× Standard_D2s_v3 Linux (2 vCPU, 8 GB each) | ~$282 |
| VMs — Identity API | 2× Standard_D2s_v3 Linux (2 vCPU, 8 GB each) | ~$282 |
| VM — Operator Web App | 1× Standard_B2s Linux (2 vCPU, 4 GB) | ~$57 |
| Standard Internal Load Balancer ×2 | API tier traffic distribution | ~$56 |
| VM OS Managed Disks ×5 (Standard SSD E10 128 GB) | Boot disk per VM | ~$74 |
| Azure Backup — VMs | 5 protected instances | ~$16 |
| Private Endpoints ×3 | SQL, Key Vault | ~$34 |
| Azure Key Vault Standard | Secret and key management | ~$8 |
| Storage Account | Diagnostics and app storage | ~$8 |
| **Subtotal** | | **~$817** |

### Other Project Resources

| Resource | Configuration | AUD/month |
|----------|--------------|----------:|
| Azure Notification Hubs Standard | Base + APNs/FCM fan-out | ~$16 |
| App Insights + Log Analytics | ~5 GB/month ingestion | ~$23 |
| **Subtotal** | | **~$39** |

### Scenario 1 Total

| | AUD |
|-|----:|
| **Monthly** | **~$903** |
| **Annual** | **~$10,836** |

---

## Scenario 2 — Proposed PaaS Architecture (APIM Premium + Container Apps + Azure SQL)

Resource group boundaries follow the SAD §3 and §6.1.5.

### Shared AIS Resource Group

| Resource | Configuration | AUD/month |
|----------|--------------|----------:|
| Azure APIM Premium (1 unit) ² | Cloud Ops funded — reference cost only | ~$4,330 |
| Container Apps Environment (Consumption) | Shared infrastructure; no standing charge | $0 |
| Azure SQL Database S1 | 20 DTU, 250 GB, TDE, private endpoint ¹ | ~$47 |
| **Subtotal (project cost — excl. APIM ²)** | | **~$47** |

> ¹ SQL is a dedicated Birdwatcher workload; full cost attributed to project.
> ² APIM Premium cost shown for reference only. Funded by Cloud Operations; excluded from all project totals.

### Birdwatcher Resource Group

| Resource | Configuration | AUD/month |
|----------|--------------|----------:|
| Container Apps — Operations API | Consumption, 0.5 vCPU, 1 GB, 1 min replica (24/7) | ~$53 |
| Container Apps — Identity API *(Option A only)* | Consumption, 0.25 vCPU, 0.5 GB, 1 min replica | ~$31 |
| Azure Key Vault Standard | Secret and key management | ~$8 |
| Storage Account | App and diagnostics storage | ~$8 |
| Private Endpoints ×3 | SQL, Key Vault, ACR | ~$34 |
| **Subtotal — Option A** | *(with Identity API)* | **~$134** |
| **Subtotal — Option B** | *(Entra External ID; no Identity API)* | **~$103** |

> Option B (Entra External ID — recommended in SAD §8.2.1) removes the Identity API Container App. Entra External ID is effectively free at expected WTP visitor volumes (< 50,000 MAU/month).

### Other Project Resources

| Resource | Configuration | AUD/month |
|----------|--------------|----------:|
| Azure Static Web App Standard | Operator Web App SPA hosting | ~$14 |
| Azure Container Registry Standard | Container image store | ~$31 |
| Azure Notification Hubs Standard | Base + APNs/FCM fan-out | ~$16 |
| App Insights + Log Analytics | ~5 GB/month ingestion | ~$23 |
| **Subtotal** | | **~$84** |

### Scenario 2 Totals

| Auth option | Monthly AUD | Annual AUD |
|-------------|------------:|-----------:|
| Option A *(with Identity API)* | ~$265 | ~$3,180 |
| **Option B — Entra External ID** *(recommended)* | **~$234** | **~$2,808** |

---

## Cost Comparison Summary

| Scenario | Monthly (AUD) | Annual (AUD) | Annual Saving vs. VM |
|----------|--------------:|-------------:|---------------------:|
| **VM-Based** | ~$903 | ~$10,836 | — |
| PaaS — Option A *(with Identity API)* | ~$265 | ~$3,180 | ~$7,656 |
| **PaaS — Option B — Entra External ID** *(recommended)* | **~$234** | **~$2,808** | **~$8,028** |

---

## Operational Overhead (not included in cost tables)

The following ongoing costs apply to the VM-based scenario and are absent or substantially reduced under PaaS.

| Factor | VM-Based | PaaS (Proposed) |
|--------|----------|-----------------|
| Security hardening per host | Required per VM before and after deployment | Azure platform baseline applied automatically |
| HA configuration | Custom load balancer rules, health probes, and failover scripting | Native to ACA, APIM, and Azure SQL |
| Scale-to-zero | Not available — VMs run and bill 24/7 | Container Apps Consumption — zero cost at idle |
| Zero-downtime deployments | Custom blue/green setup required per service | Revision traffic splitting (ACA) built-in |
| Vulnerability management | Team responsibility; patch cycles and tooling required | Azure responsibility at OS/runtime level |

---