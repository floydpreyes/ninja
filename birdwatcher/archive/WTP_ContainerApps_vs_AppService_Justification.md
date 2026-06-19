# Azure Container Apps vs App Service — Architecture Decision Record

**Project:** WTP Birdwatching App  
**Date:** June 2026  
**Author:** Rennie LF  
**Status:** Decided  
**Context:** Compute platform selection for Operations API and Identity API (Option A)

---

## 1. Decision

Both the **Operations API** and the **Identity API (Option A — SQL Custom Auth)** will be hosted on **Azure App Service — Elastic Premium EP1**, using existing approved MW App Service plans. No new App Service plans will be provisioned.

| Component | Plan | Region |
|-----------|------|--------|
| Operations API (dev/test) | `func-devtest-ase-ais-asp` | Australia Southeast |
| Operations API (production) | `func-prd-ae-ais-asp` | Australia East |
| Operations API (DR) | `func-prd-ase-ais-asp` | Australia Southeast |
| Identity API (Option A, if required) | Same plans as above | Respective environments |

When Entra External ID (Option B) is enabled, the Identity API Web App is removed. The App Service plans and Operations API are unaffected.

---

## 2. Context

This ADR covers the hosting platform decision for both compute components of the solution. Azure Container Apps was initially evaluated as the preferred option due to its technical advantages (immutable revisions, KEDA autoscaling, VNet-native ingress isolation). However, following assessment of delivery risk and timeline constraints, the decision was revised to use the existing approved App Service platform.

Key factors driving the final decision:

1. **Existing EP1 plans available** — Melbourne Water already operates Elastic Premium EP1 App Service plans in the required subscriptions and regions. These plans support VNet Integration (outbound) and private endpoints (inbound), satisfying the network isolation requirements without any new subnet provisioning.

2. **Container Apps is new to the tenancy** — This would be the first Container Apps environment deployed in the MW Azure tenancy. Onboarding requires new subnet allocations (permanent, non-resizable), Azure Firewall rule additions, private DNS zone configuration, and APIM connectivity validation — all carrying first-environment risk.

3. **Aggressive delivery timeline** — IaC build commences 23 June 2026 (subject to SAD sign-off). The onboarding overhead for a first Container Apps environment is estimated at 5–7 additional days and introduces firewall CR scope that may extend network team lead time.

4. **Operations API is DevOps-owned** — The DevOps team owns both the Operations API and the infrastructure. The same team that would onboard Container Apps must deliver IaC, SQL schema, and APIM configuration concurrently. Using an existing, familiar platform avoids splitting delivery capacity across a new platform and a compressed build schedule.

> **Auth delivery position as of June 2026:** Proceeding directly with Entra External ID (Option B) as the sole authentication implementation. No Identity API will be built. The Operations API is auth-provider agnostic; authentication is enforced at APIM via `validate-jwt` policy. The Identity API rows in this ADR are retained as a historical record of the Option A evaluation.

---

## 3. Options Considered

| # | Option | Summary |
|---|--------|---------|
| **A** | **Azure App Service — Elastic Premium EP1 (existing MW plans) (selected)** | **Existing approved platform. Familiar to the DevOps team. VNet Integration and private endpoints supported. No new subnet provisioning or firewall CR scope.** |
| B | Azure App Service Environment v3 (ASE v3) | Fully VNet-isolated App Service. Significantly higher base cost. |
| C | Azure Container Apps — Workload Profile Environment | Container-native PaaS with VNet injection, internal ingress, and KEDA autoscaling. First environment in MW tenancy — onboarding overhead ruled out for this timeline. |

---

## 4. Evaluation

### 4.1 Network Isolation

| Criterion | App Service (Standard/Premium) | ASE v3 | Container Apps (selected) |
|-----------|-------------------------------|--------|--------------------------|
| VNet inbound isolation | Private endpoint on App Service (Premium P1v3 minimum) | Full VNet injection — no public endpoint | Full VNet injection — internal ingress mode, no public IP |
| Outbound via VNet | VNet Integration (regional) — routes egress through VNet | Native — all traffic within VNet | Native — subnet delegated to `Microsoft.App/environments` |
| Accessible via APIM over VNet | Yes, with private endpoint configured | Yes | Yes — internal load balancer IP in VNet |
| Public endpoint disabled | Only with private endpoint + `publicNetworkAccess: Disabled` | Yes by default | Yes — internal ingress mode |

**Finding:** App Service Standard plan does not natively prevent public inbound access — a private endpoint requires the Premium v2/v3 plan minimum ($$$). ASE v3 provides equivalent isolation but at a significantly higher base cost. Container Apps with internal ingress provides equivalent inbound isolation at a fraction of the cost.

---

### 4.2 Hosting Cost

| Plan | Estimated Monthly Base Cost | Scale to Zero | Outbound VNet Integration | Private Endpoint (inbound) |
|------|-----------------------------|---------------|--------------------------|---------------------------|
| App Service B1/B2 | ~AUD $25–60/month per instance | No | ❌ Not supported on Basic | ✅ Supported (Basic and above) |
| App Service S1 (production) | ~AUD $100–130/month per instance | No | ✅ Regional VNet Integration | ✅ Supported |
| App Service P1v3 | ~AUD $230–280/month per instance | No | ✅ Regional VNet Integration | ✅ Supported |
| ASE v3 (Isolated v2, I1v2) | ~AUD $600–750/month base stamp + per-instance | No | ✅ Native | ✅ Native |
| **Container Apps Consumption (scale-to-zero)** | **Pay-per-vCPU-second / per-GiB-second** | **Yes** | **✅ Native (VNet injection)** | **✅ No public endpoint at platform level** |
| **Container Apps Consumption (min 1 replica)** | **~AUD $85–95/month per API (0.5–1 vCPU, 1–2 GiB)** | **No (warm)** | **✅ Native** | **✅ Internal ingress — no public IP** |
| Container Apps Dedicated (D4) | ~AUD $350–450/month per node | No | ✅ Native | ✅ Internal ingress | 

> **Correction note:** Private endpoints for App Service are available from **Basic tier and above** (not Premium-only as previously stated). However, outbound VNet Integration (required to reach SQL and Key Vault private endpoints within the VNet) is only available from **Standard (S1) and above**. Basic tier apps with a private endpoint cannot route outbound traffic into the VNet. For this solution, which requires both inbound isolation and outbound VNet routing to SQL/Key Vault private endpoints, the minimum viable App Service tier is **Standard S1**.

**Production cost comparison — both APIs, full network isolation (inbound + outbound):**

| Scenario | Monthly Cost (2 APIs) | Inbound Isolation | Outbound via VNet |
|----------|-----------------------|-------------------|-------------------|
| App Service S1 × 2 + private endpoints + VNet Integration | ~AUD $230–260/month | ✅ Private endpoint per app | ✅ VNet Integration |
| **Container Apps Consumption, min 1 replica × 2 APIs** | **~AUD $250–280/month** | **✅ No public endpoint at platform level — internal ingress** | **✅ VNet injection (native)** |

**Finding:** At production scale, App Service S1 with private endpoints and Container Apps Consumption with minimum replicas are **comparable in cost** for this workload. Cost is therefore not the primary differentiator. The decision rests on security posture, container delivery model, operational simplicity, and the Option B decommission path — all covered in the sections below.

---

### 4.3 Container Delivery Model

Both APIs are containerised workloads with ACR-based delivery pipelines. This has an important security implication beyond just the deployment model:

| Criterion | App Service | Container Apps |
|-----------|-------------|----------------|
| Container image deployment | Supported via "Deploy as container" — but App Service runtime manages the OS | Native — OCI container image is the unit of deployment |
| Revision traffic splitting | Deployment slots (2 slots on Standard, limited) | Native revision management — percentage-based traffic splitting across multiple active revisions |
| Zero-downtime deployment | Slot swap (warm-up, then swap) | Revision traffic split then promote — no swap window required |
| Multi-container apps | Not supported natively | Supported — sidecar containers in same replica |
| **Deployment immutability** | **Mutable — in-place file overwrites, Kudu console access, mutable slot state** | **Immutable — each revision is a pinned OCI image digest; running code cannot be modified** |
| **Audit trail** | App Service deployment logs; no image digest pinning | Each revision records the exact ACR image digest deployed — you always know what is running |

**Finding:** Container Apps is the natural hosting target for a containerised workload with ACR-based delivery. App Service container support is functional but bolt-on. The immutability of Container Apps revisions is a material security advantage — no Kudu console, no SSH access, no mutable file system in production replicas.

---

### 4.4 Autoscaling

| Criterion | App Service | Container Apps |
|-----------|-------------|----------------|
| Scale mechanism | Metric-based (CPU, Memory, HTTP queue) | KEDA — event-driven: HTTP, CPU, Memory, Azure Service Bus, custom scalers |
| Scale to zero | No (minimum 1 instance) | Yes on Consumption plan |
| Scale triggers | Platform metrics only | Any KEDA scaler — HTTP requests, queue depth, custom |
| Scale granularity | Instance (VM-level) | Replica (container-level) |

**Finding:** KEDA-based autoscaling is more granular and supports event-driven scale-out patterns. For the Operations API, HTTP-based KEDA scaling with scale-to-zero on dev/test eliminates idle compute cost.

---

### 4.5 Security Posture

Container Apps provides a stronger default security posture than App Service Standard/S1 without requiring premium tiers:

| Security Control | App Service S1 | App Service P1v3 | Container Apps (internal ingress) |
|-----------------|---------------|-----------------|----------------------------------|
| **No public inbound endpoint** | ❌ Public endpoint exists by default | ✅ Private endpoint can be attached (P1v3 minimum) | ✅ Internal ingress — no public IP on the environment at any tier |
| **Immutable production deployments** | ❌ Mutable in-place — Kudu, file system, slot state | ❌ Same | ✅ Each revision is a pinned, immutable OCI image digest |
| **No remote access surface** | ❌ Kudu console, SSH access available | ❌ Same | ✅ No Kudu, no SSH — replicas are read-only containers |
| **Outbound via VNet** | ✅ VNet Integration (regional) | ✅ VNet Integration | ✅ Native — subnet delegated to `Microsoft.App/environments` |
| **Managed Identity** | ✅ Supported | ✅ Supported | ✅ Supported |
| **Image provenance** | Deployment logs only | Deployment logs only | ✅ ACR image digest recorded per revision — auditable what ran and when |

**Finding:** To achieve equivalent inbound isolation on App Service, a P1v3 plan + private endpoint is required (more than double the cost of S1). Container Apps internal ingress eliminates the public endpoint at the platform level regardless of tier — no private endpoint resource required. Immutable revisions and the absence of Kudu/SSH reduce the attack surface on running production replicas.

---

### 4.6 Platform Management Consolidation

With both APIs on Container Apps, the entire compute layer is a single platform:

| Concern | Two-platform model (App Service + Container Apps) | Single-platform model (Container Apps only) |
|---------|--------------------------------------------------|--------------------------------------------|
| IaC templates | Separate Bicep/Terraform modules for App Service plan, site, VNet integration + Container Apps environment, apps | Single Bicep/Terraform module for Container Apps environment + two Container App resources |
| CI/CD pipelines | Separate pipeline for App Service deploy (`az webapp deploy`) + Container Apps deploy (`az containerapp update`) | Single pipeline pattern: build image → push to ACR → `az containerapp update` |
| Monitoring | Two Log Analytics sources, two App Insights resources if separate | One Log Analytics workspace, one App Insights resource, shared via the environment |
| Networking | VNet Integration (App Service) + VNet injection (Container Apps) — different models, different subnets | Single VNet injection, single subnet, single private DNS zone |
| RBAC | App Service RBAC + Container Apps RBAC — two separate role models | Container Apps RBAC only |
| Option B decommission | App Service plan teardown + private endpoint removal + VNet integration cleanup + APIM route update | `az containerapp delete ca-identity-api` + APIM route update — no infrastructure changes |

**Finding:** A single-platform model eliminates operational divergence across IaC, pipelines, monitoring, and networking. The decommission path when Entra External ID is enabled is a single CLI command with no infrastructure side effects.

---

### 4.6 Shared Container Apps Environment — Both APIs

Both APIs are deployed as separate Container Apps within the same Container Apps environment:

| Component | Container App | Workload Profile | Notes |
|-----------|--------------|-----------------|-------|
| **Identity API** | `ca-identity-api` | Consumption (scale-to-zero) | Interim — Option A only. Low-volume auth traffic suits scale-to-zero. Decommissioned when Option B is enabled. |
| **Operations API** | `ca-operations-api` | Consumption (dev/test) / Dedicated D4 (prod) | Permanent component. KEDA HTTP scaler, minimum replicas in production. |

Both apps share the same environment, subnet, Log Analytics workspace, internal DNS, and Managed Identity configuration. APIM routes `/api/auth/*` and `/api/profile/*` to the Identity API internal ingress FQDN and all other paths to the Operations API internal ingress FQDN — both resolved via the shared private DNS zone.

> **Fallback:** If the Identity API codebase cannot be containerised within the delivery timeline, it can be hosted on Azure App Service (S1) with VNet integration as a temporary measure. This is the only scenario where App Service would be introduced. The networking and APIM routing changes required are minimal.

#### Option B Cutover Impact on Hosting

When Entra External ID is enabled:

| Change | Detail |
|--------|--------|
| Identity API Container App | `az containerapp delete` — clean removal, no environment impact |
| APIM Public Product policy | Updated to validate JWTs via Entra External ID OIDC discovery endpoint (replacing custom `validate-jwt` signing key) |
| `/api/auth/*` and `/api/profile/*` routes | Removed from APIM routing table (or redirected if a profile-only endpoint is retained in Operations API) |
| Container Apps environment | Unchanged — Operations API continues on same environment |
| Subnet / DNS / firewall rules | No change required |

The cutover is isolated to a single `containerapp delete` and APIM policy update. It does not affect the Container Apps environment, subnet allocations, or Operations API deployments.

---

### 4.7 Observability

Both platforms support App Insights SDK integration and Log Analytics. Container Apps additionally provides:
- Built-in container log streaming
- Revision-level metrics (per-revision replica counts, CPU, Memory)
- System log stream for environment-level events

No material disadvantage versus App Service.

---

### 4.8 Operational Considerations for First Deployment

Because this is the first Container Apps environment in the MW Azure tenancy, the following additional steps are required:

| Action | Owner | Notes |
|--------|-------|-------|
| Register `Microsoft.App` resource provider in subscription | DevOps | One-time per subscription |
| Plan and provision VNet subnets (delegated to `Microsoft.App/environments`) | DevOps / Network | See Section 6 — one subnet per environment, permanent sizing |
| Configure Azure Firewall application and network rules | DevOps / Network | See Section 5 — required before environment can pull images and reach platform services |
| Confirm APIM can reach Container Apps internal load balancer IP | DevOps | APIM must be VNet-integrated or injected in same/peered VNet |
| Establish ACR integration and Managed Identity pull permission | DevOps | `AcrPull` role on ACR for Container Apps Managed Identity |
| Configure private DNS zone for internal ingress | DevOps / Network | `<unique-id>.<region>.azurecontainerapps.io` → static internal IP |

---

## 5. Azure Firewall Rules

When the Container Apps environment egress is routed through Azure Firewall via a User-Defined Route (UDR), the following rules must be added to the Azure Firewall policy.

> **Note:** Configure either application rules OR network rules for each scenario — not both simultaneously. Application rules are recommended where available as they provide FQDN-level control.

### 5.1 Application Rules (FQDN-based)

| Priority | Scenario | Target FQDNs | Protocol | Purpose |
|----------|----------|--------------|----------|---------|
| 100 | All scenarios | `mcr.microsoft.com`, `*.data.mcr.microsoft.com` | HTTPS:443 | Microsoft Artifact Registry — Container Apps platform images |
| 110 | All scenarios | `packages.aks.azure.com`, `acs-mirror.azureedge.net` | HTTPS:443 | Underlying AKS cluster binaries (Kubernetes, CNI) |
| 120 | Azure Container Registry | `<acr-name>.azurecr.io`, `*.blob.core.windows.net`, `login.microsoft.com` | HTTPS:443 | Pull container images from ACR; blob storage backing layer |
| 130 | Azure Key Vault | `<keyvault-name>.vault.azure.net`, `login.microsoft.com` | HTTPS:443 | Secret retrieval (used with network rule `AzureKeyVault`) |
| 140 | Managed Identity | `*.identity.azure.net`, `login.microsoftonline.com`, `*.login.microsoftonline.com`, `*.login.microsoft.com` | HTTPS:443 | Managed Identity token acquisition |
| 150 | Azure Notification Hubs | — | — | Use network rule `ServiceBus` service tag (see Section 5.2) |

> Replace `<acr-name>` with `wtpbirdwatchingacr` (or the actual ACR name confirmed at deployment).  
> Replace `<keyvault-name>` with the Key Vault hostname confirmed at deployment.

### 5.2 Network Rules (Service Tag–based)

| Priority | Scenario | Service Tags | Destination Ports | Purpose |
|----------|----------|--------------|-------------------|---------|
| 200 | All scenarios | `MicrosoftContainerRegistry`, `AzureFrontDoorFirstParty` | 443 | Microsoft Artifact Registry (alternative to application rules) |
| 210 | Azure Container Registry | `AzureContainerRegistry`, `AzureActiveDirectory` | 443 | ACR image pull + authentication |
| 220 | Azure Key Vault | `AzureKeyVault`, `AzureActiveDirectory` | 443 | Key Vault access + Entra ID token |
| 230 | Managed Identity | `AzureActiveDirectory` | 443 | Managed Identity token endpoint |
| 240 | Azure Notification Hubs | `ServiceBus` | 443, 5671, 5672 | Notification Hubs AMQP/HTTPS egress |
| 250 | Azure SQL (private endpoint) | Internal VNet CIDR only | 1433 | SQL traffic stays within VNet — no firewall traversal needed if private endpoint is in same VNet |
| 260 | Azure Monitor / App Insights | `AzureMonitor` | 443 | Telemetry and log egress |

> **SQL note:** If Azure SQL private endpoint is in the same VNet as the Container Apps environment, SQL traffic does not traverse the firewall — it routes directly to the private endpoint NIC. Only add a firewall rule if SQL is in a peered VNet and traffic crosses a firewall boundary.

### 5.3 UDR Configuration

A User-Defined Route table must be created and associated with the **Container Apps subnet** (not the firewall subnet):

```
Route name:    DefaultEgress
Address prefix: 0.0.0.0/0
Next hop type:  Virtual appliance
Next hop IP:    <Azure Firewall private IP>
```

> The Azure Firewall private IP is found under the firewall resource → IP Configurations.

---

## 6. Subnet Plan

Each Container Apps environment requires **its own dedicated subnet**, delegated exclusively to `Microsoft.App/environments`. The subnet cannot be shared with any other Azure resource and **cannot be resized after environment creation**.

### 6.1 Subnet Sizing Reference

| CIDR | Usable IPs | Max replicas (Consumption)* | Max nodes (Dedicated)* |
|------|-----------|----------------------------|------------------------|
| /27 | 18 | ~90 replicas | 6 nodes |
| /26 | 50 | ~250 replicas | 25 nodes |
| /25 | 114 | ~570 replicas | 57 nodes |
| /24 | 242 | ~1,210 replicas | 121 nodes |
| /23 | 498 | ~2,490 replicas | 249 nodes |

*Accounting for 12 IPs reserved by Container Apps infrastructure + 5 Azure subnet-reserved IPs. Consumption replicas assume 10 replicas share 1 IP. During single-revision-mode deployments, available address space is temporarily halved to support zero-downtime revision rollover.

### 6.2 Proposed Subnets

> **Note:** Each Container Apps environment requires a separate dedicated subnet delegated to `Microsoft.App/environments`. Subnets cannot be resized after the environment is created — confirm sizing with the MW network team before provisioning.
>
> The DR subnet (`sn-prd-ais-ae-aca`) resides in a **separate VNet in Australia Southeast** — it is not a second subnet in the primary VNet. See Section 6.5 for DR topology.

| Environment | Environment Type | Subnet Name | CIDR | VNet / Region | Delegation | Rationale |
|-------------|-----------------|-------------|------|---------------|------------|-----------|
| **Dev/Test** | Workload Profile (Consumption) | `sn-dev-test-ais-aca` | `172.26.155.0/26` | Primary VNet — Australia East | `Microsoft.App/environments` | Scale-to-zero — /26 provides ~250 replica capacity, sufficient for dev/test workloads |
| **UAT** | Workload Profile (Consumption or Dedicated D4) | `sn-uat-ais-aca` | `172.26.85.0/26` | Primary VNet — Australia East | `Microsoft.App/environments` | /26 provides headroom for UAT load testing scenarios |
| **Production** | Workload Profile (Dedicated D4 or Consumption with min replicas) | `sn-prd-ais-ase-aca` | `172.26.32.0/24` | Primary VNet — Australia East | `Microsoft.App/environments` | /24 provides 1,210 replica capacity with room for zero-downtime revision rollover |
| **DR** | Workload Profile (Dedicated or Consumption) | `sn-prd-ais-ae-aca` | `172.27.17.0/24` | DR VNet — Australia Southeast | `Microsoft.App/environments` | Separate environment in secondary region — same sizing as production. See Section 6.5. |

### 6.3 Subnet Delegation

All Container Apps subnets must be delegated to `Microsoft.App/environments` at creation. Azure CLI examples using the confirmed subnet names and CIDRs:

```bash
# Dev/Test
az network vnet subnet create \
  --resource-group <rg-network> \
  --vnet-name <primary-vnet-name> \
  --name sn-dev-test-ais-aca \
  --address-prefixes 172.26.155.0/26 \
  --delegations Microsoft.App/environments

# UAT
az network vnet subnet create \
  --resource-group <rg-network> \
  --vnet-name <primary-vnet-name> \
  --name sn-uat-ais-aca \
  --address-prefixes 172.26.85.0/26 \
  --delegations Microsoft.App/environments

# Production
az network vnet subnet create \
  --resource-group <rg-network> \
  --vnet-name <primary-vnet-name> \
  --name sn-prd-ais-ase-aca \
  --address-prefixes 172.26.32.0/24 \
  --delegations Microsoft.App/environments

# DR (in DR VNet — Australia Southeast)
az network vnet subnet create \
  --resource-group <rg-network-dr> \
  --vnet-name <dr-vnet-name> \
  --name sn-prd-ais-ae-aca \
  --address-prefixes 172.27.17.0/24 \
  --delegations Microsoft.App/environments
```

Or via Bicep (production example):

```bicep
resource subnetAcaProd 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: 'sn-prd-ais-ase-aca'
  parent: vnet
  properties: {
    addressPrefix: '172.26.32.0/24'
    delegations: [
      {
        name: 'aca-delegation'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
}
```

### 6.4 Additional Subnets Required (Non-Container Apps)

The following companion subnets are also required in support of the Container Apps architecture. CIDRs are placeholders — confirm allocation with the MW network team:

| Subnet Name | Purpose | Notes |
|-------------|---------|-------|
| `snet-privateendpoints` | Private endpoint NICs for Azure SQL, Key Vault, ACR | Normal subnet — no delegation. One NIC per private endpoint. Minimum /27. |
| `snet-apim` (if APIM VNet-injected) | APIM Standard v2 VNet integration | Required if APIM needs to route to Container Apps internal ingress. Minimum /28. |
| `AzureFirewallSubnet` | Azure Firewall | Must be named exactly `AzureFirewallSubnet` — minimum /26. |
| `AzureFirewallManagementSubnet` | Azure Firewall Management (if forced tunnelling) | Must be named exactly `AzureFirewallManagementSubnet` — minimum /26. |

> Subnets cannot be resized after Container Apps environment creation.

---

### 6.5 DR Topology — How Disaster Recovery Works in Container Apps

#### The key point: DR requires a separate Container Apps Environment, not a second subnet

A Container Apps environment is a **single-region resource**. It is bound to one Azure region and one dedicated subnet. You cannot stretch a single environment across regions or add a second subnet to achieve DR. To provide a DR capability, a **fully separate Container Apps environment** must be deployed in the secondary region (Australia Southeast), with its own dedicated subnet (`sn-prd-ais-ae-aca`, `172.27.17.0/24`) in a separate DR VNet.

#### DR Architecture Options

| Option | Description | RTO / RPO | Complexity |
|--------|-------------|-----------|------------|
| **Active/Passive (Cold standby)** | DR environment exists but runs zero replicas (scale-to-zero). Traffic only fails over if primary is declared failed. | RTO: minutes to tens of minutes (cold start time) | Low — one extra environment, no active traffic routing |
| **Active/Passive (Warm standby)** | DR environment runs minimum replica count at all times, ready to accept traffic. APIM or Front Door handles failover routing. | RTO: seconds to low minutes | Medium — ongoing replica cost in DR |
| **Active/Active** | Both environments serve live traffic simultaneously, load balanced by Azure Front Door or Traffic Manager. | Near-zero RTO | High — dual data plane, session consistency, SQL geo-replication required |

**Recommended for this workload:** Active/Passive (Warm standby) — the Operations API is stateless (state in SQL), so warm replicas in DR can accept traffic immediately after a DNS/routing failover. SQL geo-replication or active geo-replication covers the data tier.

#### What the DR Deployment Includes

Each environment in the DR region is a full parallel deployment:

| Resource | DR Requirement |
|----------|----------------|
| Container Apps Environment | Separate environment in Australia Southeast, VNet-injected into DR VNet (`sn-prd-ais-ae-aca`) |
| Container Apps (Operations API) | Same container image from ACR — deployed as a separate Container App in the DR environment |
| Azure Container Registry | ACR is geo-replicated (Standard tier supports geo-replication) — same image available in both regions |
| Azure SQL | Active geo-replication or failover group — DR SQL endpoint in Australia Southeast |
| Key Vault | Separate Key Vault in DR region, or use Key Vault with geo-redundancy (Premium tier) |
| APIM | APIM Standard v2 supports multi-region — add Australia Southeast gateway unit, or deploy a second APIM in DR region |
| Private DNS zones | DR VNet requires its own private DNS zones linked for SQL, Key Vault, and Container Apps internal ingress |
| Azure Firewall | Separate firewall (or NVA) in DR VNet with equivalent rule set |

#### Failover Routing

Traffic routing failover is controlled at the layer above APIM — either:
- **Azure Front Door** (recommended) — health probe–based automatic failover between primary APIM and DR APIM endpoints
- **Azure Traffic Manager** — DNS-based failover with configurable probe intervals
- **Cloudflare Load Balancing** — if Cloudflare is already the edge, failover can be configured at the Cloudflare origin pool level

#### Summary Diagram

```
Cloudflare / Azure Front Door
       │
  ┌────┴────────────────────┐
  │                         │
APIM (AUS East)         APIM (AUS Southeast)  ← failover target
  │                         │
Container Apps Env       Container Apps Env (DR)
  sn-prd-ais-ase-aca        sn-prd-ais-ae-aca
  172.26.32.0/24            172.27.17.0/24
  │                         │
Azure SQL (primary) ──── Azure SQL (geo-replica)
```

> **Bottom line:** The DR subnet (`sn-prd-ais-ae-aca`) is in a separate VNet in Australia Southeast and hosts a fully independent Container Apps environment. It is not an additional subnet in the primary VNet.

---

## 7. Decision Outcome

**Azure App Service (Elastic Premium EP1 — existing MW plans) is the hosting platform for the Operations API**, based on:

1. Existing EP1 plans (`func-prd-ae-ais-asp`, `func-prd-ase-ais-asp`, `func-devtest-ase-ais-asp`) are already deployed, approved, and operated within the MW tenancy — no new infrastructure provisioning required for the compute layer.
2. EP1 supports both VNet Integration (outbound to SQL and Key Vault private endpoints) and private endpoints (inbound restriction to APIM only) — meeting the network isolation requirements without introducing a new subnet or firewall CR scope.
3. Container Apps onboarding overhead (4 new dedicated subnets, Azure Firewall rule additions, private DNS zones, first-environment unknowns) is estimated at 5–7 additional delivery days and was incompatible with the aggressive June–August 2026 timeline.
4. Entra External ID (Option B) has been confirmed as the sole authentication implementation — no Identity API will be built. The Identity API analysis in this ADR is retained as a historical evaluation record only.
5. APIM remains the security boundary — the Operations API is not publicly reachable; inbound access is restricted via private endpoint to APIM outbound IPs only.

**Platform state:**

| Component | Hosting | Plan | Notes |
|-----------|---------|------|-------|
| **Operations API** | Azure App Service (Web App) | Existing EP1 plans | DevOps-owned; VNet Integration + private endpoint; deployment slot swap for zero-downtime |
| **Identity API** | Not built | — | Entra External ID adopted directly — no custom Identity API required |
| **Operator Web App** | Azure Static Web App | — | Web Development team; Entra ID (MW internal tenant) for operator auth |

Sections 5 and 6 of this ADR (Azure Firewall rules and subnet plan) were written for the Container Apps option and are **superseded** by this decision. They are retained as reference material only in the event the platform decision is revisited in future.

---

## 8. References

| Document | URL |
|----------|-----|
| Azure App Service — VNet Integration | https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration |
| Azure App Service — Private Endpoints | https://learn.microsoft.com/en-us/azure/app-service/networking/private-endpoint |
| Azure App Service — Elastic Premium Plan | https://learn.microsoft.com/en-us/azure/azure-functions/functions-premium-plan |
| Azure App Service — Deployment Slots | https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots |
| Azure Container Apps — Virtual Network Configuration *(superseded option — reference only)* | https://learn.microsoft.com/en-us/azure/container-apps/custom-virtual-networks |
| MW SAD — WTP Birdwatching App v0.2 | MW Solution Architecture - WTP Birdwatching App v0.2.md |
