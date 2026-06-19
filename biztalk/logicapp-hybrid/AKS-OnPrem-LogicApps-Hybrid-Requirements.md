__AKS On-Premises Infrastructure Requirements__
__Logic Apps Standard — Hybrid Deployment__

---

__Overview__

This document outlines the infrastructure required to support Azure Logic Apps Standard in hybrid deployment mode, hosted on Azure Arc-enabled AKS Edge Essentials running on Windows Server VMs. This model is required for on-premises-to-on-premises integration workloads where workflows must execute within the Melbourne Water network boundary.

---

__Architecture__

```
Azure (Control Plane)
├── Azure Arc                        ← cluster management and visibility
├── Container Apps extension         ← installed on Arc cluster
├── Connected Environment             ← Arc-backed ACA environment
├── Azure Container Registry         ← Logic Apps runtime image
├── Key Vault                        ← secrets and connection strings
└── Log Analytics Workspace          ← monitoring and diagnostics

On-Premises (VMware vSphere)
├── Windows Server VM(s)             ← AKS Edge Essentials nodes
│   └── CBL-Mariner Linux VM         ← hosted by AKS EE hypervisor (auto-managed)
│       └── Logic Apps runtime       ← Container App running workflows
├── SQL Server instance              ← workflow state storage
└── SMB file share                   ← workflow definitions, maps, schemas
```

AKS Edge Essentials (AKS EE) runs a lightweight managed Linux VM (CBL-Mariner) inside each Windows Server host using the built-in hypervisor. This Linux VM hosts the Kubernetes node. Nested virtualisation must be enabled on each VMware VM.

---

__Dev Environment — Single Node__

One Windows Server VM hosting AKS EE in single-machine mode.

| Component | Specification |
|---|---|
| OS | Windows Server 2022 (recommended) or 2019 |
| vCPU | 8 vCPU |
| RAM | 16 GB |
| OS disk | 128 GB (SSD-backed datastore) |
| Data disk | 64 GB (for AKS EE VM storage) |
| Network | Single NIC, VLAN with outbound 443 access |
| Nested virtualisation | Enabled in vSphere VM settings |
| AKS EE mode | Single machine (no clustering) |

SQL Server and SMB share for dev can be co-located on the same VM or reuse existing dev/test SQL and file server infrastructure if available.

---

__Production Environment — Multi-Node__

Two Windows Server VMs hosting AKS EE in scalable (multi-machine) cluster mode, joined as a single Arc-enabled cluster.

| Component | Node 1 | Node 2 |
|---|---|---|
| Role | Control plane + worker | Worker |
| OS | Windows Server 2022 | Windows Server 2022 |
| vCPU | 8 vCPU | 8 vCPU |
| RAM | 32 GB | 32 GB |
| OS disk | 128 GB (SSD-backed) | 128 GB (SSD-backed) |
| Data disk | 128 GB | 128 GB |
| Network | Single NIC, production VLAN | Single NIC, production VLAN |
| Nested virtualisation | Enabled | Enabled |
| AKS EE mode | Scalable cluster (primary) | Scalable cluster (joined) |

Nodes must be on the same L2 network segment or have L3 reachability with low latency. A virtual IP (VIP) is required for the cluster API server endpoint — this can be satisfied with a static IP allocation from the production network range.

__Production SQL Server__

A dedicated SQL Server instance (or AlwaysOn Availability Group) is required for production workflow state. This must not be shared with application databases.

| Requirement | Detail |
|---|---|
| SQL Server version | SQL Server 2019 or 2022 |
| Database | Dedicated database for Logic Apps state |
| HA | AlwaysOn AG recommended; SQL failover cluster acceptable |
| Authentication | SQL auth credentials stored in Azure Key Vault |
| Connectivity | Accessible from AKS EE node VMs on port 1433 |

__Production SMB File Share__

| Requirement | Detail |
|---|---|
| Protocol | SMB 3.0+ |
| Share access | AKS EE node computer accounts or a dedicated service account |
| Connectivity | Accessible from AKS EE node VMs |
| Location | Existing MW file server or DFS share acceptable |

---

__VMware vSphere Requirements__

| Item | Requirement |
|---|---|
| vSphere version | 6.7 U3 or later (7.x recommended) |
| Nested virtualisation | Must be enabled per-VM (`Expose hardware-assisted virtualization to guest OS`) |
| vSphere HA | Enabled on the cluster hosting the AKS EE VMs |
| VM hardware version | 14 or later |
| Datastore | SSD-backed or all-flash; spinning disk not supported |
| Resource pool | Dedicated resource pool with CPU/memory reservations recommended |

---

__Networking Requirements__

| Traffic | Direction | Ports | Destination |
|---|---|---|---|
| Azure Arc control plane | Outbound | 443 | `*.arc.azure.com`, `*.his.arc.azure.com` |
| Azure Container Registry | Outbound | 443 | ACR endpoint |
| Azure Key Vault | Outbound | 443 | `*.vault.azure.net` |
| Log Analytics | Outbound | 443 | `*.ods.opinsights.azure.com` |
| AKS EE inter-node | Internal | Various | Between AKS EE VMs (prod only) |
| SQL Server | Internal | 1433 | From AKS EE VMs to SQL host |
| SMB | Internal | 445 | From AKS EE VMs to file server |
| On-prem systems | Internal | Application-specific | Systems being integrated |

All outbound Azure endpoints can be routed via the existing ExpressRoute circuit. A proxy server is supported by Arc if direct outbound internet is not permitted.

---

__Azure Requirements__

| Resource | Notes |
|---|---|
| Azure Arc | Subscription-level resource; one per cluster |
| Container Apps extension | Installed via `az k8s-extension create` on the Arc cluster |
| Connected Environment | One per environment (dev / prod) |
| Azure Container Registry | Can be shared across environments |
| Key Vault | One per environment recommended |
| Log Analytics Workspace | One per environment recommended |
| Service Principal or Managed Identity | Required for Arc onboarding and ACR pull |

---

__Deployment Sequence__

1. Provision Windows Server VMs in vSphere with nested virtualisation enabled
2. Install AKS Edge Essentials on each VM; join nodes into scalable cluster (prod) or leave as single-machine (dev)
3. Arc-enable the cluster — `az connectedk8s connect`
4. Install the Container Apps extension on the Arc cluster — `az k8s-extension create`
5. Create the Connected Environment in Azure — targets the Arc cluster
6. Provision SQL Server database and SMB share; store credentials in Key Vault
7. Deploy Logic Apps Standard app targeting the Connected Environment
8. Validate workflow execution and Log Analytics telemetry

---

__Assumptions and Dependencies__

- MW VMware platform team provisions and manages the Windows Server VMs and enables nested virtualisation
- SQL Server infrastructure (prod) is provisioned and supported by MW's database team; this is a platform dependency, not in migration project scope
- SMB file share is provisioned by MW's file/storage team
- Outbound 443 connectivity from the AKS EE VMs to Azure Arc endpoints is approved and routed (via ExpressRoute or direct internet path, subject to MW network policy)
- Azure subscription, resource group, and RBAC access for Arc onboarding is arranged with MW's Azure platform team prior to deployment
- AKS EE version and Logic Apps runtime image compatibility must be validated at time of deployment against current Microsoft support matrix
