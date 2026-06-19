# On-Premises Infrastructure Build Request — Dev / POC
## Logic Apps Standard — Hybrid Deployment

**Prepared by:** Melbourne Water AIS Team  
**Date:** 26 May 2026  

---

## Purpose

Build request for a single Windows Server VM to support Azure Logic Apps Standard running in hybrid mode on AKS Edge Essentials (AKS EE). This environment will serve as the proof-of-concept (POC) for the Melbourne Water integration platform migration.

---

## Critical VMware Prerequisite — Nested Virtualisation

> **This is a hard requirement. AKS Edge Essentials will not function without it.**

AKS Edge Essentials runs a lightweight managed Linux VM (CBL-Mariner) inside the Windows Server VM using the built-in Hyper-V hypervisor. For this to work on VMware vSphere, nested virtualisation must be explicitly enabled on the VM.

| vSphere Setting | Value |
|---|---|
| Expose hardware-assisted virtualization to the guest OS | **Enabled** (VM settings → CPU → Hardware virtualization) |
| VM hardware version | **14 or later** |

This setting must be applied **before** the VM is first powered on, or requires a power-off to change.

---

## VMware Platform Requirements

| Item | Requirement |
|---|---|
| vSphere version | 6.7 U3 minimum — **7.x strongly recommended** |
| vSphere HA | Enabled on the cluster hosting this VM |
| VM hardware version | 14 or later |
| Nested virtualisation | Enabled (see above) |
| Snapshots during operation | Not supported while AKS EE is running — snapshot only when VM is powered off |

---

## VM Specification

| Component | Specification |
|---|---|
| VM name | **`svaisaksdev01`** |
| Quantity | 1 VM |
| Operating system | **Windows Server 2022 Datacenter** (Desktop Experience) |
| vCPU | **8 vCPU** |
| RAM | **16 GB** |
| OS disk | **128 GB** — thin provisioned, SSD-backed datastore |
| Data disk | **64 GB** — separate VMDK, SSD-backed datastore, presented as a dedicated disk (unformatted — do not mount or format) |
| Network adapters | 1 × VMXNET3 NIC |
| Nested virtualisation | **Enabled** |
| VM hardware version | 14 or later |

---

## Operating System Configuration

| Item | Requirement |
|---|---|
| Windows activation | Licensed and activated |
| Windows Updates | Fully patched at time of handover |
| Time synchronisation | NTP configured and synchronised to MW domain time source |
| Domain join | **Required** — join to the Melbourne Water Active Directory domain |
| Windows Firewall | Enabled; outbound TCP 443 permitted (see Network Requirements) |
| Add mwc\rennielf-admin & mwc\thankappanr-admin to server admins

---

## Service Account

A single domain service account is required. It will be used for both SQL Server access and SMB file share access on `svaisaksdev01`.

| Item | Requirement |
|---|---|
| Account type | Active Directory domain service account — **non-interactive** |
| Account name | _(e.g. `svc-aisaks-dev` — confirm with MW AD team)_ |
| Password | Complex password — documented and provided to MW AIS team |
| Password expiry | **Set to never expire** (service account) |
| Interactive logon | **Denied** — apply the following user rights via Group Policy or local policy on `svaisaksdev01`: `Deny log on locally`, `Deny log on through Remote Desktop Services` |
| Account lockout | Ensure account is excluded from standard lockout policy — a locked service account will stop Logic Apps runtime |
| Local group membership on `svaisaksdev01` | Add to local **Users** group (minimum required; do not add to Administrators) |

---

## SQL Server

SQL Server Express is required for Logic Apps workflow state storage, co-located on `svaisaksdev01`.

| Item | Requirement |
|---|---|
| SQL Server version | **SQL Server Express 2022** |
| Instance type | Default instance preferred; named instance acceptable |
| Authentication mode | **Mixed mode** (SQL Server Authentication enabled) |
| Dedicated database | Blank database named `LogicAppsDev` — created and online |
| Database login | Grant the domain service account (see Service Account section) `db_owner` on `LogicAppsDev` |
| Port | TCP 1433 — enabled in SQL Server Configuration Manager (disabled by default in Express) |
| SQL Server Browser | **Enabled and started** (required if using a named instance) |

---

## SMB File Share

| Item | Requirement |
|---|---|
| Share path | `\\svaisaksdev01\LogicAppsShare` |
| Share permissions | Domain service account (see Service Account section) — **Change** |
| NTFS permissions | Domain service account — **Modify** |
| Location | Local folder on `svaisaksdev01` — e.g. `C:\LogicAppsShare` |

---

## Network Requirements

### IP Allocation

> **AKS Edge Essentials note:** AKS EE creates Linux VMs via Hyper-V that appear directly on the same subnet as `svaisaksdev01`. Additional IPs from the same subnet must be reserved (not DHCP) and provided below before AKS EE installation begins.

| Item | Value |
|---|---|
| Hostname | `svaisaksdev01` |
| Static IP | ___________ |
| Subnet mask | ___________ |
| Default gateway | ___________ |
| DNS servers | ___________ |
| NTP server | ___________ |
| VLAN | Dev / integration VLAN |
| **AKS EE — Linux node IP** | ___________ |
| **AKS EE — Control plane endpoint IP** | ___________ |
| **AKS EE — Kubernetes service IP pool (start)** | ___________ |
| **AKS EE — Kubernetes service IP pool (count)** | 5 _(MW AIS team will consume up to 5 IPs from this pool)_ |

### Firewall Rules Required

| Source | Destination | Port | Direction | Purpose |
|---|---|---|---|---|
| `svaisaksdev01` | `*.arc.azure.com`, `*.his.arc.azure.com` | TCP 443 | Outbound | Azure Arc control plane |
| `svaisaksdev01` | ACR endpoint (to be confirmed) | TCP 443 | Outbound | Container image pulls |
| `svaisaksdev01` | `*.vault.azure.net` | TCP 443 | Outbound | Azure Key Vault |
| `svaisaksdev01` | `*.ods.opinsights.azure.com` | TCP 443 | Outbound | Log Analytics / monitoring |
| `svaisaksdev01` | `mcr.microsoft.com` | TCP 443 | Outbound | Microsoft Container Registry |
| Developer workstations | `svaisaksdev01` | TCP 443, 8080 | Inbound | Logic Apps designer / management |
| `svaisaksdev01` | On-premises integrated systems | App-specific | Outbound | Integration target systems |

All outbound Azure traffic should be routed via the **existing ExpressRoute circuit**. If a proxy server is required, provide the proxy hostname and port to the MW AIS team before AKS EE installation begins.

---

## Handover Checklist

Complete all items before handing the VM to the MW AIS team.

### VM and OS

- [ ] AKS EE IP allocation confirmed with MW network team — Linux node IP, control plane endpoint IP, and 5-IP service pool reserved as static (not DHCP) on the same subnet as `svaisaksdev01`
- [ ] VM named `svaisaksdev01` provisioned per spec (8 vCPU, 16 GB RAM, 128 GB OS disk, 64 GB data disk)
- [ ] Windows Server 2022 Datacenter (Desktop Experience) installed, licensed, and fully patched
- [ ] Nested virtualisation enabled in vSphere VM settings (CPU → Hardware virtualization)
- [ ] VM hardware version 14 or later confirmed
- [ ] Data disk presented as a separate unformatted disk (visible in Disk Management as Disk 1 — **do not format**)
- [ ] VM joined to Melbourne Water Active Directory domain
- [ ] Static IP assigned, default gateway configured, DNS resolving
- [ ] Outbound TCP 443 to Azure Arc confirmed: `Test-NetConnection arc.azure.com -Port 443` returns `TcpTestSucceeded : True`
- [ ] Outbound TCP 443 to MCR confirmed: `Test-NetConnection mcr.microsoft.com -Port 443` returns `TcpTestSucceeded : True`
- [ ] Windows time synchronisation confirmed: `w32tm /query /status` shows a valid time source

### Service Account

- [ ] Domain service account created in Active Directory (name confirmed with MW AD team)
- [ ] Account type set to non-interactive (no interactive logon permitted)
- [ ] `Deny log on locally` user right applied to the account on `svaisaksdev01`
- [ ] `Deny log on through Remote Desktop Services` user right applied to the account on `svaisaksdev01`
- [ ] Password set to never expire
- [ ] Account excluded from standard lockout policy
- [ ] Account added to local Users group on `svaisaksdev01`
- [ ] Service account credentials (username and password) documented and provided to MW AIS team

### SQL Server

- [ ] SQL Server Express 2022 installed on `svaisaksdev01`
- [ ] Mixed mode authentication enabled
- [ ] TCP/IP protocol enabled in SQL Server Configuration Manager (disabled by default in Express)
- [ ] SQL Server Browser service enabled and started (if using named instance)
- [ ] Windows Firewall inbound rule created for TCP 1433
- [ ] `LogicAppsDev` database created
- [ ] Domain service account granted `db_owner` on `LogicAppsDev`
- [ ] TCP 1433 listening confirmed: `Test-NetConnection localhost -Port 1433` returns `TcpTestSucceeded : True`

### SMB File Share

- [ ] Folder `C:\LogicAppsShare` created on `svaisaksdev01`
- [ ] `LogicAppsShare` SMB share created pointing to that folder
- [ ] Share permissions: domain service account set to **Change**
- [ ] NTFS permissions: domain service account set to **Modify**
- [ ] Share accessible: `Test-Path \\svaisaksdev01\LogicAppsShare` returns `True` from the VM itself

*This document covers the dev/POC on-premises infrastructure only. Azure resource provisioning, AKS EE software installation, Arc onboarding, and Logic Apps deployment are handled separately by the MW AIS team.*
