# On-Premises Infrastructure Build Request — Dev / POC
## Logic Apps Standard — Hybrid Deployment (Linux / K3s / Azure Arc)

**Prepared by:** Melbourne Water AIS Team  
**Date:** 28 May 2026  
**Variant:** Linux + K3s (no nested virtualisation required)

---

## Purpose

Build request for a single Linux VM to support Azure Logic Apps Standard running in hybrid mode on a K3s Kubernetes cluster connected to Azure via Azure Arc. This environment will serve as the proof-of-concept (POC) for the Melbourne Water integration platform migration.

This document is an alternative to the Windows Server / AKS Edge Essentials build request. The Linux / K3s approach eliminates the nested virtualisation requirement, making it compatible with standard VMware vSphere configurations without any special CPU settings.

---

## Approach Overview

| Layer | Technology |
|---|---|
| Hypervisor | VMware vSphere (standard — no nested virtualisation required) |
| Guest OS | Red Hat Enterprise Linux 9.x (RHEL 9) |
| Container runtime | containerd (installed as part of K3s) |
| Kubernetes distribution | K3s (single-node) |
| Azure connectivity | Azure Arc-enabled Kubernetes |
| Logic Apps runtime | Logic Apps Standard extension via Azure Arc |
| Workflow state storage | SQL Server 2022 on Linux (co-located) |
| Kubernetes storage | K3s local-path provisioner (PersistentVolumes on local disk) |

The MW AIS team installs and configures K3s, Azure Arc, and the Logic Apps extension after the VM is handed over. The infrastructure team is responsible only for the items in this document.

---

## VMware Platform Requirements

| Item | Requirement |
|---|---|
| vSphere version | 6.7 U3 minimum — 7.x recommended |
| vSphere HA | Enabled on the cluster hosting this VM |
| VM hardware version | 13 or later (standard — no special requirement) |
| Nested virtualisation | **Not required** |
| Snapshots | Standard VMware snapshots supported (no restrictions) |

---

## VM Specification

| Component | Specification |
|---|---|
| VM name | **`svaisaksdev01`** |
| Quantity | 1 VM |
| Operating system | **Red Hat Enterprise Linux (RHEL) 9.x** |
| vCPU | **8 vCPU** |
| RAM | **16 GB** |
| OS disk | **128 GB** — thin provisioned, SSD-backed datastore |
| Data disk | **64 GB** — separate VMDK, SSD-backed datastore, presented as unformatted (do not mount or format — MW AIS team will partition and mount as a K3s data volume) |
| Network adapters | 1 × VMXNET3 NIC |
| VM hardware version | 13 or later |

---

## Operating System Configuration

| Item | Requirement |
|---|---|
| RHEL version | 9.x — minimal server install (no desktop GUI) |
| RHEL subscription | Active Red Hat subscription required — confirm with MW IT before provisioning |
| OS updates | Fully patched at time of handover (`dnf upgrade` completed) |
| SELinux | Enforcing mode — **do not disable**; the MW AIS team will configure K3s SELinux policy after handover |
| Time synchronisation | `chronyd` configured and synchronised to MW domain NTP source |
| Domain join | **Not required** for this VM — see Service Account section |
| SSH access | OpenSSH server enabled — credentials managed via CyberArk (see CyberArk section) |
| Privileged admin accounts | Grant `mwc\rennielf-admin` and `mwc\thankappan-admin` sudo access via CyberArk onboarding |
| Firewall | `firewalld` enabled; outbound TCP 443 permitted (see Network Requirements) |
| open-vm-tools | Installed and running (`dnf install open-vm-tools`) |
| `curl`, `wget`, `git`, `jq` | Installed (`dnf install curl wget git jq`) |

---

## CyberArk Privileged Access

`svaisaksdev01` must be onboarded to the Melbourne Water CyberArk Privileged Access Manager (PAM) instance before handover. All privileged SSH access to this server is managed through CyberArk — no static SSH credentials should be left on the server after onboarding.

| Item | Requirement |
|---|---|
| CyberArk onboarding | Enrol `svaisaksdev01` as a target in CyberArk PAM |
| Access method | SSH through CyberArk PSM (Privileged Session Manager) |
| Accounts granted access | `mwc\rennielf-admin` and `mwc\thankappan-admin` |
| Permissions | Both accounts granted full `sudo` access on `svaisaksdev01` |
| Local root password | Set a strong random password; vault in CyberArk — do not document externally |
| SSH key rotation | CyberArk to manage SSH key rotation for the vaulted accounts |
| Direct SSH | Direct SSH access (bypassing CyberArk) should be restricted to the CyberArk PSM server IP only via `firewalld` after onboarding is confirmed |

> **Note to CyberArk team:** The SSH daemon on `svaisaksdev01` runs on the standard TCP 22. The PSM connector type is **SSH — Linux**. Confirm the CyberArk platform policy with the MW PAM administrator before onboarding.

---

## Service Account

Because this VM is not domain-joined, a local Linux service account is used for the Logic Apps runtime process. This is appropriate for the POC environment.

| Item | Requirement |
|---|---|
| Account type | Local Linux service account |
| Account name | `svc-ais-aks-dev` |
| Shell | `/usr/sbin/nologin` (non-interactive — cannot log in) |
| Home directory | `/var/lib/svc-ais-aks-dev` — created and owned by this account |
| sudo access | None — do not add to sudo group |
| Password | Not required (no interactive logon) |
| Creation command | `useradd --system --no-create-home --shell /usr/sbin/nologin --home-dir /var/lib/svc-ais-aks-dev svc-ais-aks-dev` |

---

## Network Requirements

### IP Allocation

> **Note:** Unlike the AKS Edge Essentials variant, this deployment does not require additional IPs for nested VMs. Only a single static IP is needed for `svaisaksdev01`. K3s uses the host's IP for all Kubernetes API and service traffic.

| Item | Value |
|---|---|
| Hostname | `svaisaksdev01` |
| Static IP | ___________ |
| Subnet mask | ___________ |
| Default gateway | ___________ |
| DNS servers | ___________ |
| NTP server | ___________ |
| VLAN | Dev / integration VLAN |

> K3s Kubernetes services use `NodePort` or the host IP directly for the POC. No additional IP pool is required. If `LoadBalancer`-type services are needed in future, a tool such as MetalLB can be added later with a small reserved IP range.

### Firewall Rules Required

| Source | Destination | Port | Direction | Purpose |
|---|---|---|---|---|
| `svaisaksdev01` | `*.arc.azure.com`, `*.his.arc.azure.com` | TCP 443 | Outbound | Azure Arc control plane |
| `svaisaksdev01` | ACR endpoint (to be confirmed) | TCP 443 | Outbound | Container image pulls |
| `svaisaksdev01` | `*.vault.azure.net` | TCP 443 | Outbound | Azure Key Vault |
| `svaisaksdev01` | `*.ods.opinsights.azure.com` | TCP 443 | Outbound | Log Analytics / monitoring |
| `svaisaksdev01` | `mcr.microsoft.com` | TCP 443 | Outbound | Microsoft Container Registry |
| `svaisaksdev01` | `subscription.rhsm.redhat.com`, `cdn.redhat.com` | TCP 443 | Outbound | RHEL subscription registration and package updates |
| `svaisaksdev01` | `raw.githubusercontent.com` | TCP 443 | Outbound | Helm install script and SMB CSI driver Helm chart (steps 4.5 and 6.6) |
| CyberArk PSM server | `svaisaksdev01` | TCP 22 | Inbound | SSH via CyberArk Privileged Session Manager |
| Developer workstations | `svaisaksdev01` | TCP 22 | Inbound | SSH (pre-CyberArk handover only — restrict after CyberArk onboarding confirmed) |
| Developer workstations | `svaisaksdev01` | TCP 443, 8080 | Inbound | Logic Apps designer / management |
| `svaisaksdev01` | On-premises integrated systems | App-specific | Outbound | Integration target systems |

All outbound Azure traffic should be routed via the **existing ExpressRoute circuit**. If a proxy server is required, the K3s and Azure Arc installations must be configured with proxy settings — provide the proxy hostname and port to the MW AIS team before any software installation begins.

---

## Handover Checklist

Complete all items before handing the VM to the MW AIS team.

### VM and OS

- [ ] VM named `svaisaksdev01` provisioned per spec (8 vCPU, 16 GB RAM, 128 GB OS disk, 64 GB data disk)
- [ ] RHEL 9.x installed — minimal server install, no desktop GUI
- [ ] Active RHEL subscription registered (`subscription-manager status` shows `Overall Status: Current`)
- [ ] OS fully patched (`dnf upgrade` completed)
- [ ] SELinux confirmed in enforcing mode (`getenforce` returns `Enforcing`)
- [ ] `open-vm-tools` installed and running (`systemctl status open-vm-tools`)
- [ ] `curl`, `wget`, `git`, `jq` installed
- [ ] Static IP assigned, default gateway configured, DNS resolving (`nmcli dev show | grep DNS` shows correct DNS servers)
- [ ] NTP synchronised (`timedatectl` shows `NTP service: active` and `System clock synchronized: yes`)
- [ ] Data disk visible as an unformatted, unmounted disk (`lsblk` shows second disk — **do not format or mount**)
- [ ] SSH server running and accessible on TCP 22
- [ ] CyberArk PAM: `svaisaksdev01` onboarded as an SSH target
- [ ] CyberArk PAM: `mwc\rennielf-admin` granted access with full sudo
- [ ] CyberArk PAM: `mwc\thankappan-admin` granted access with full sudo
- [ ] CyberArk PAM: local root password vaulted in CyberArk
- [ ] After CyberArk onboarding confirmed: `firewalld` rule updated to restrict TCP 22 inbound to CyberArk PSM server IP only
- [ ] Outbound TCP 443 to Azure Arc confirmed: `curl -v https://arc.azure.com` returns HTTP response (not connection refused)
- [ ] Outbound TCP 443 to MCR confirmed: `curl -v https://mcr.microsoft.com` returns HTTP response
- [ ] Outbound TCP 443 to GitHub confirmed: `curl -v https://raw.githubusercontent.com` returns HTTP response (required for Helm install and SMB CSI driver Helm chart)

### Service Account

- [ ] Local service account `svc-ais-aks-dev` created with shell set to `/usr/sbin/nologin`
- [ ] Account is non-interactive — confirm `su - svc-ais-aks-dev` is denied or produces no shell
- [ ] Home directory `/var/lib/svc-ais-aks-dev` created and owned by `svc-ais-aks-dev`
- [ ] Account credentials (if any) documented and provided to MW AIS team

---

## Items Handled by MW AIS Team After Handover

The following are **not** part of this infrastructure build request. The MW AIS team will complete these after the VM is handed over:

- K3s single-node Kubernetes installation (including `k3s-selinux` RPM policy package for RHEL SELinux compatibility)
- Data disk partitioning, formatting, and mounting at `/var/lib/rancher/k3s`
- Azure Arc onboarding (`az connectedk8s connect`)
- Logic Apps Standard extension deployment via Arc
- Logic Apps app and workflow deployment
- SQL Server 2022 for Linux installation, database creation, and Logic Apps SQL login configuration
- Azure Key Vault integration
- Container image pull configuration

---

*This document covers the dev/POC on-premises infrastructure only. Azure resource provisioning, K3s installation, Arc onboarding, and Logic Apps deployment are handled separately by the MW AIS team.*
