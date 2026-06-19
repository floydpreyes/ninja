# On-Premises Infrastructure Build Request
## Logic Apps Standard — Hybrid Deployment (POC / Dev then Production)
### Melbourne Water — Third-Party Provider Handoff

**Prepared by:** Melbourne Water Integration Team  
**Date:** 26 May 2026  
**Classification:** Internal / Provider Handoff

---

## Purpose

This document is a build request for the third-party infrastructure provider. It specifies the on-premises virtual machine, storage, network, SQL Server, and file share resources required to support Azure Logic Apps Standard running in hybrid mode on AKS Edge Essentials (AKS EE).

Two environments are required — **Dev/POC** (single node, to be built first) and **Production** (two-node cluster, to follow after POC sign-off).

---

## Critical VMware Prerequisite — Nested Virtualisation

> **This is a hard requirement. AKS Edge Essentials will not function without it.**

AKS Edge Essentials runs a lightweight managed Linux VM (CBL-Mariner) inside each Windows Server VM using the built-in Hyper-V hypervisor. For this to work on VMware vSphere, nested virtualisation must be explicitly enabled on every VM.

| vSphere Setting | Value |
|---|---|
| Expose hardware-assisted virtualization to the guest OS | **Enabled** (VM settings → CPU → Hardware virtualization) |
| VM hardware version | **14 or later** |

This setting must be applied **before** the VM is first powered on, or requires a power-off to change. Do not provision the VMs without confirming this is enabled.

---

## VMware Platform Requirements

| Item | Requirement |
|---|---|
| vSphere version | 6.7 U3 minimum — **7.x strongly recommended** |
| vSphere HA | Enabled on the cluster hosting these VMs |
| VM hardware version | 14 or later |
| Datastore type | **SSD-backed or all-flash only** — spinning disk is not supported |
| Resource pool | Dedicated resource pool with CPU and memory reservations recommended |
| Nested virtualisation | Enabled per-VM (see above) |
| Snapshots during operation | Not supported while AKS EE is running — snapshot only when VM is powered off |

---

## Environment 1 — Dev / POC (Build First)

Single Windows Server VM. This is the first environment to be provisioned and will serve as the proof-of-concept before production is committed.

### VM Specification

| Component | Specification |
|---|---|
| Quantity | 1 VM |
| Operating system | **Windows Server 2022 Datacenter** (Desktop Experience) |
| vCPU | **8 vCPU** |
| RAM | **16 GB** |
| OS disk | **128 GB** — thin provisioned, SSD-backed datastore |
| Data disk | **64 GB** — separate VMDK, SSD-backed datastore, presented as a dedicated disk (not part of OS volume) |
| Network adapters | 1 × VMXNET3 NIC |
| VLAN | Dev/integration VLAN — see Network Requirements |
| Nested virtualisation | **Enabled** |
| VM hardware version | 14 or later |
| VM name (suggested) | `MW-AKSEE-DEV-01` |

### Operating System Configuration Required

| Item | Requirement |
|---|---|
| Windows activation | Licensed and activated |
| Windows Updates | Fully patched at time of handover |
| Local administrator account | Credentials provided to MW integration team |
| Time synchronisation | NTP configured and synchronised to MW domain time source |
| Domain join | **Not required** — workgroup is acceptable for AKS EE |
| Windows Defender / AV | AV exclusions will be required post-handover (MW team to configure) |
| Firewall | Windows Firewall enabled; outbound 443 allowed (see Network Requirements) |

### Dev SQL Server

SQL Server for dev workflow state storage. This can be a **shared existing dev SQL instance** if one is available, or a new SQL Express / Developer instance installed on the same VM.

| Item | Requirement |
|---|---|
| SQL Server version | SQL Server 2019 or 2022 (Express acceptable for POC) |
| Instance type | Default instance preferred; named instance acceptable |
| Authentication | **SQL Server Authentication enabled** (mixed mode) |
| Dedicated database | A blank database named `LogicAppsDev` (or similar) created and accessible |
| SQL login | A dedicated SQL login with `db_owner` on the Logic Apps database |
| Port | 1433 accessible from localhost (loopback) — no cross-host firewall needed for single-node dev |
| Location | Same VM or existing shared dev SQL host |

### Dev SMB File Share

| Item | Requirement |
|---|---|
| Share path | `\\MW-AKSEE-DEV-01\LogicAppsShare` (or equivalent on existing file server) |
| Share permissions | Local administrator or dedicated service account — **Read/Write** |
| NTFS permissions | Same account — **Modify** |
| Location | Local folder on the dev VM is acceptable for POC |

---

## Environment 2 — Production (To Follow After POC Sign-Off)

Two Windows Server VMs forming an AKS EE scalable cluster. **Do not begin production build until the POC has been signed off.**

### VM Specifications

| Component | Node 1 (Control Plane + Worker) | Node 2 (Worker) |
|---|---|---|
| Quantity | 1 VM | 1 VM |
| Operating system | Windows Server 2022 Datacenter | Windows Server 2022 Datacenter |
| vCPU | **8 vCPU** | **8 vCPU** |
| RAM | **32 GB** | **32 GB** |
| OS disk | **128 GB** — SSD-backed | **128 GB** — SSD-backed |
| Data disk | **128 GB** — separate VMDK, SSD-backed | **128 GB** — separate VMDK, SSD-backed |
| Network adapters | 1 × VMXNET3 NIC | 1 × VMXNET3 NIC |
| VLAN | Production integration VLAN | Production integration VLAN |
| Nested virtualisation | **Enabled** | **Enabled** |
| VM hardware version | 14 or later | 14 or later |
| VM name (suggested) | `MW-AKSEE-PRD-01` | `MW-AKSEE-PRD-02` |

### Cluster Networking — Production Specific

| Requirement | Detail |
|---|---|
| L2 adjacency | Both VMs must be on the **same L2 network segment** (same VLAN), or L3 with sub-1ms latency |
| Static IP — Node 1 | Allocated from production integration VLAN range |
| Static IP — Node 2 | Allocated from production integration VLAN range |
| Virtual IP (VIP) | **1 additional static IP** required from the same range — used as the AKS EE cluster API server endpoint |
| DNS entries | `A` records required for Node 1, Node 2, and the VIP (names to be confirmed with MW integration team) |

### Production SQL Server

A **dedicated** SQL Server instance for workflow state. Must not be shared with application databases.

| Item | Requirement |
|---|---|
| SQL Server version | **SQL Server 2019 or 2022** — Standard or Enterprise |
| Instance | Dedicated instance (not shared with other workloads) |
| High availability | **SQL Server AlwaysOn AG recommended** — SQL FCI acceptable if AG not available |
| Authentication | Mixed mode (SQL Server Authentication enabled) |
| Dedicated database | Blank database created; name to be confirmed |
| SQL login | Dedicated SQL login with `db_owner` on the Logic Apps database |
| Port | 1433 reachable from both AKS EE VMs (`MW-AKSEE-PRD-01`, `MW-AKSEE-PRD-02`) |
| Firewall | Inbound 1433 open from production integration VLAN to SQL host |

### Production SMB File Share

| Item | Requirement |
|---|---|
| Protocol | **SMB 3.0 or later** |
| Share location | Existing MW DFS namespace or dedicated file server — confirm with MW storage team |
| Share permissions | Dedicated service account (to be created by MW team) — **Read/Write** |
| NTFS permissions | Same service account — **Modify** |
| Availability | Share must be highly available (DFS-R or clustered file server) |
| Connectivity | Accessible on port 445 from both AKS EE VMs |

---

## Network Requirements — On-Premises Firewall / VLAN Rules

These rules must be in place before the AKS EE installation begins. The MW network team will need to implement these; include with the build request as a separate firewall change request if required.

### Dev Environment Firewall Rules

| Source | Destination | Port / Protocol | Direction | Purpose |
|---|---|---|---|---|
| `MW-AKSEE-DEV-01` | `*.arc.azure.com`, `*.his.arc.azure.com` | TCP 443 outbound | Outbound | Azure Arc control plane |
| `MW-AKSEE-DEV-01` | ACR endpoint (to be confirmed) | TCP 443 outbound | Outbound | Container image pulls |
| `MW-AKSEE-DEV-01` | `*.vault.azure.net` | TCP 443 outbound | Outbound | Azure Key Vault |
| `MW-AKSEE-DEV-01` | `*.ods.opinsights.azure.com` | TCP 443 outbound | Outbound | Log Analytics / monitoring |
| `MW-AKSEE-DEV-01` | `mcr.microsoft.com` | TCP 443 outbound | Outbound | Microsoft Container Registry |
| Developer workstations | `MW-AKSEE-DEV-01` | TCP 443, 8080 | Inbound | Logic Apps designer / management |

All outbound Azure traffic should be routed via the **existing ExpressRoute circuit**. If a proxy server is required, the proxy hostname and port must be provided to the MW integration team prior to AKS EE installation.

### Production Environment Firewall Rules

| Source | Destination | Port / Protocol | Direction | Purpose |
|---|---|---|---|---|
| `MW-AKSEE-PRD-01/02` | `*.arc.azure.com`, `*.his.arc.azure.com` | TCP 443 | Outbound | Azure Arc control plane |
| `MW-AKSEE-PRD-01/02` | ACR endpoint | TCP 443 | Outbound | Container image pulls |
| `MW-AKSEE-PRD-01/02` | `*.vault.azure.net` | TCP 443 | Outbound | Azure Key Vault |
| `MW-AKSEE-PRD-01/02` | `*.ods.opinsights.azure.com` | TCP 443 | Outbound | Log Analytics |
| `MW-AKSEE-PRD-01/02` | `mcr.microsoft.com` | TCP 443 | Outbound | Microsoft Container Registry |
| `MW-AKSEE-PRD-01` | `MW-AKSEE-PRD-02` | Various (AKS inter-node) | Internal | AKS EE cluster communication |
| `MW-AKSEE-PRD-02` | `MW-AKSEE-PRD-01` | Various (AKS inter-node) | Internal | AKS EE cluster communication |
| `MW-AKSEE-PRD-01/02` | SQL Server host | TCP 1433 | Internal | Workflow state database |
| `MW-AKSEE-PRD-01/02` | File server / DFS | TCP 445 | Internal | SMB workflow storage |
| `MW-AKSEE-PRD-01/02` | On-premises integrated systems | App-specific | Internal | Integration target systems |

> **AKS EE inter-node ports:** AKS EE requires multiple internal ports between cluster nodes including TCP 6443, 10250, 2379–2380 (etcd), and UDP 8472 (VXLAN). Full port list available from Microsoft AKS EE documentation. For simplicity, permit all traffic between the two AKS EE VMs within the production VLAN.

---

## IP Address Allocation Request

Complete and return to MW integration team before build commences.

| Item | Environment | Requested IP | DNS Name |
|---|---|---|---|
| Node 1 static IP | Dev | ___________ | ___________ |
| Node 1 static IP | Production | ___________ | ___________ |
| Node 2 static IP | Production | ___________ | ___________ |
| Cluster VIP | Production | ___________ | ___________ |
| Gateway | Dev | ___________ | — |
| Gateway | Production | ___________ | — |
| DNS servers | Both | ___________ | — |
| NTP server | Both | ___________ | — |

---

## Handover Checklist — Provider to Complete

Before handing VMs to the MW integration team, confirm all items below are complete.

### Dev VM (`MW-AKSEE-DEV-01`)

- [ ] VM provisioned per spec (8 vCPU, 16 GB RAM, 128 GB OS disk, 64 GB data disk)
- [ ] Windows Server 2022 Datacenter installed, licensed, and fully patched
- [ ] Nested virtualisation enabled in vSphere VM settings
- [ ] VM hardware version 14 or later confirmed
- [ ] Data disk presented as a separate disk (visible in Disk Management as Disk 1, unformatted)
- [ ] Static IP assigned, default gateway set, DNS resolving
- [ ] Outbound TCP 443 to Azure Arc endpoints confirmed (test with `Test-NetConnection` to `arc.azure.com` on port 443)
- [ ] Local administrator credentials documented and provided to MW integration team
- [ ] Windows time synchronisation confirmed (`w32tm /query /status`)
- [ ] SQL Server installed and SQL login credentials provided (if co-located)
- [ ] SMB share created and accessible (if co-located)
- [ ] VM accessible via RDP from MW integration team workstations

### Production VMs (`MW-AKSEE-PRD-01`, `MW-AKSEE-PRD-02`)

- [ ] Both VMs provisioned per spec (8 vCPU, 32 GB RAM, 128 GB OS disk, 128 GB data disk each)
- [ ] Windows Server 2022 Datacenter installed, licensed, and fully patched on both nodes
- [ ] Nested virtualisation enabled on both VMs
- [ ] Both VMs on the same VLAN / L2 segment
- [ ] Static IPs assigned to both nodes and the cluster VIP allocated
- [ ] DNS `A` records created for both nodes and VIP
- [ ] Inter-node connectivity confirmed (ping and port tests between the two VMs)
- [ ] Outbound TCP 443 to Azure Arc endpoints confirmed from both VMs
- [ ] SQL Server instance provisioned, dedicated database created, SQL login credentials provided
- [ ] SMB file share accessible from both VMs on port 445
- [ ] All firewall rules implemented per the table above
- [ ] Local administrator credentials documented and provided to MW integration team

---

## Contact and Escalation

| Role | Name | Contact |
|---|---|---|
| MW Integration Lead | _(to be completed)_ | — |
| MW Network Team | _(to be completed)_ | — |
| MW VMware Platform Team | _(to be completed)_ | — |
| MW Database Team | _(to be completed)_ | — |
| Third-Party Provider PM | _(to be completed)_ | — |

---

*This document covers on-premises infrastructure only. Azure resource provisioning, AKS EE software installation, Arc onboarding, and Logic Apps deployment are handled separately by the MW integration team.*
