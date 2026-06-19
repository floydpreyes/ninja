# K3s + Azure Arc + Logic Apps Standard Hybrid — Setup Runbook
## Melbourne Water AIS Team — Dev / POC Environment

**Applies to:** `svaisaksdev01` (RHEL 9.x) after infrastructure handover  
**Last updated:** 3 June 2026 (revised — validated against Microsoft docs)  
**Prerequisites:** VM provisioned and handed over per *AIS Linux K3s Dev box request.md*

---

## Overview

This runbook covers all steps performed by the MW AIS team after VM handover:

1. [Prepare data disk](#1-prepare-data-disk)
2. [Install K3s](#2-install-k3s)
3. [Verify K3s](#3-verify-k3s)
4. [Install Azure CLI and Helm](#4-install-azure-cli-and-helm)
5. [Onboard to Azure Arc](#5-onboard-to-azure-arc)
6. [Install Container Apps Arc extension and SMB CSI driver](#6-install-container-apps-arc-extension-and-smb-csi-driver)
7. [Configure Samba SMB file share](#7-configure-samba-smb-file-share)
8. [Configure SQL Server](#8-configure-sql-server)
9. [Create Logic App hybrid resource and deploy a workflow](#9-create-logic-app-hybrid-resource-and-deploy-a-workflow)
10. [Configure Entra app registration for managed connectors](#10-configure-entra-app-registration-for-managed-connectors)
11. [Operational notes](#11-operational-notes)

---

## Architecture on This VM

All components run on the single `svaisaksdev01` VM:

| Component | What it is | Location |
|---|---|---|
| K3s | Single-node Kubernetes | `svaisaksdev01` — systemd service |
| Azure Arc agents | Arc connectivity | K3s `azure-arc` namespace |
| Container Apps extension | Enables Logic Apps hybrid runtime | K3s `logicapps-aca-ns` namespace |
| Logic Apps runtime | Workflow execution (container) | K3s `logicapps-aca-ns` namespace |
| SQL Server 2022 | Workflow state and run history | `svaisaksdev01` — systemd service |
| Samba (SMB) | Workflow artifact file share | `svaisaksdev01` — systemd service |

> **Important — disconnected operation limit:** Logic Apps hybrid tolerates up to **24 hours** of Azure disconnection while continuing to process workflows locally. Logging data beyond 24 hours of disconnection may be lost. Plan maintenance windows accordingly.

---

## Assumptions

- You are logged in via PAM-managed SSH as `mwc\rennielf-admin` or `mwc\thankappan-admin` (full sudo)
- Azure subscription is available and you can authenticate via `az login`
- Azure resource group in **Australia East** is pre-created or you have permission to create it
  > Note: Australia East support for Logic Apps hybrid has been confirmed by the Melbourne Water Microsoft account manager. The public Microsoft documentation has not yet been updated to list it — proceed with Australia East.
- ExpressRoute connectivity to Azure is active

---

## 1. Prepare Data Disk

The 64 GB data disk was delivered unformatted. K3s must store its data at `/var/lib/rancher/k3s` — mounting the dedicated disk here **before** K3s install ensures K3s writes to the data disk, not the OS disk.

### 1.1 Identify the data disk

```bash
lsblk
```

Expected output — look for the 64 GB disk with no mount point (typically `/dev/sdb`):

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  128G  0 disk
├─sda1   8:1    0    1G  0 part /boot
└─sda2   8:2    0  127G  0 part /
sdb      8:16   0   64G  0 disk        ← this is the data disk
```

> **Note:** Device name may differ (`/dev/sdc`, etc.). Confirm size matches the 64 GB spec. **Do not confuse with the OS disk.**

### 1.2 Partition the disk

```bash
sudo parted /dev/sdb --script mklabel gpt mkpart primary xfs 0% 100%
```

### 1.3 Format with XFS

```bash
sudo mkfs.xfs -f /dev/sdb1
```

### 1.4 Create the mount point

```bash
sudo mkdir -p /var/lib/rancher/k3s
```

### 1.5 Get the disk UUID

```bash
sudo blkid /dev/sdb1
```

Copy the `UUID=` value from the output.

### 1.6 Add to fstab for persistent mount

```bash
sudo tee -a /etc/fstab <<EOF
UUID=<paste-uuid-here>  /var/lib/rancher/k3s  xfs  defaults,noatime  0  2
EOF
```

### 1.7 Mount and verify

```bash
sudo mount -a
df -h /var/lib/rancher/k3s
```

Expected: shows ~64 GB available at `/var/lib/rancher/k3s`.

---

## 2. Install K3s

> **Network CIDR pre-flight — confirm before installing:**  
> K3s allocates two internal CIDR blocks that must not overlap any Melbourne Water subnet, even though they are never routed to the corporate network. Overlapping ranges cause ambiguous routing tables and complicate future network changes.
>
> | K3s network | Default CIDR | Used for |
> |---|---|---|
> | Pod network | `10.42.0.0/16` | Container IP addresses inside every K3s pod |
> | Service network | `10.43.0.0/16` | Virtual ClusterIP addresses for Kubernetes Services |
>
> Known MW subnets from the DMZ L3 diagram are `10.248.x.x` (Brooklyn DC1) and `10.249.x.x` (Hoppers DC2). The K3s defaults do not overlap these. However, **confirm with the MW network team that no internal subnet, VPN pool, voice/SCADA/IoT range, or future allocation uses `10.42.0.0/16` or `10.43.0.0/16`** before proceeding. If a conflict exists, change the values in step 2.3 and update the firewall rules in steps 7.7 and 8.5 to match.

### 2.1 Install the K3s SELinux policy package

This **must** be done before the K3s installer runs, or the install will fail on RHEL with SELinux enforcing.

```bash
sudo dnf install -y container-selinux
sudo dnf install -y https://rpm.rancher.io/k3s/latest/common/centos/9/noarch/k3s-selinux-1.6.0-1.el9.noarch.rpm
```

Verify the policy installed:

```bash
sudo rpm -q k3s-selinux
```

### 2.2 Confirm SELinux is still enforcing

```bash
getenforce
```

Must return `Enforcing`. If not, stop and investigate — do not proceed with SELinux disabled.

### 2.3 Run the K3s install script

Set the pod and service CIDRs explicitly. Confirm these values are free in the MW IP plan (see CIDR pre-flight note above) before running.

```bash
# Change these only if MW uses 10.42.x.x or 10.43.x.x elsewhere in the network
K3S_POD_CIDR="10.42.0.0/16"
K3S_SVC_CIDR="10.43.0.0/16"

# Persist for use in later steps (firewall rules)
echo "export K3S_POD_CIDR=${K3S_POD_CIDR}" >> ~/.bashrc
echo "export K3S_SVC_CIDR=${K3S_SVC_CIDR}" >> ~/.bashrc

curl -sfL https://get.k3s.io | sh -s - \
  --cluster-cidr=${K3S_POD_CIDR} \
  --service-cidr=${K3S_SVC_CIDR}
```

This installs K3s as a systemd service and starts it automatically.

> **Proxy note:** If the environment requires an HTTP proxy, prefix the command:
> ```bash
> curl -sfL https://get.k3s.io | HTTPS_PROXY=http://<proxy>:<port> sh -s - \
>   --cluster-cidr=${K3S_POD_CIDR} --service-cidr=${K3S_SVC_CIDR}
> ```
> You must also set `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY` environment variables for the K3s service — see [K3s proxy docs](https://docs.k3s.io/advanced#configuring-an-http-proxy).

### 2.4 Enable K3s to start on boot

```bash
sudo systemctl enable k3s
```

---

## 3. Verify K3s

### 3.1 Check service status

```bash
sudo systemctl status k3s
```

Expect: `active (running)`.

### 3.2 Check the node is Ready

```bash
sudo k3s kubectl get nodes
```

Expected output:

```
NAME           STATUS   ROLES                  AGE   VERSION
svaisaksdev01  Ready    control-plane,master   1m    v1.33.x+k3s1
```

### 3.3 Check system pods are running

```bash
sudo k3s kubectl get pods -n kube-system
```

All pods should be `Running` or `Completed`. Wait up to 3 minutes for first-time startup.

### 3.4 Set up kubectl access for your user session

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config
```

Add to `~/.bashrc` for persistence:

```bash
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
```

Verify:

```bash
kubectl get nodes
```

---

## 4. Install Azure CLI and Helm

### 4.1 Import Microsoft repository

```bash
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
```

### 4.2 Install Azure CLI

```bash
sudo dnf install -y azure-cli
```

### 4.3 Verify

```bash
az version
```

### 4.4 Install required Azure CLI extensions

```bash
az extension add --name connectedk8s
az extension add --name k8s-extension
az extension add --name customlocation
az extension add --name containerapp
az extension add --name logicapp
```

### 4.5 Install Helm

The SMB CSI driver and Container Apps extension are deployed via Helm.

> **Network requirement — `raw.githubusercontent.com`:** The Helm install script is fetched directly from `https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3`. Outbound TCP 443 to `raw.githubusercontent.com` must be permitted before running this command. The same domain is also used in step 6.6 to add the SMB CSI driver Helm chart repository.

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### 4.6 Log in to Azure

```bash
az login --use-device-code
```

Follow the device code prompt. If using a service principal:

```bash
az login --service-principal -u <appId> -p <password> --tenant <tenantId>
```

### 4.7 Set subscription

```bash
az account set --subscription "<MW Azure Subscription Name or ID>"
```

### 4.8 Register required resource providers (first time only)

These providers are not enabled by default in a new Azure subscription. All six are required for this POC — registering an unused provider has no cost or security impact; it simply unlocks the API surface.

| Resource provider | What it unlocks in this POC |
|---|---|
| `Microsoft.Kubernetes` | Lets Azure Resource Manager recognise and manage the K3s cluster on `svaisaksdev01` as an Azure resource (the Arc-connected cluster object) |
| `Microsoft.KubernetesConfiguration` | Enables the Arc extension framework — required to install the Container Apps extension onto the K3s cluster in Step 6 |
| `Microsoft.ExtendedLocation` | Enables Custom Locations — the mechanism that projects the on-premises K3s namespace into Azure as a target region, so Azure Portal can deploy Logic Apps *to the MW datacentre* rather than to an Azure region |
| `Microsoft.App` | Registers the Azure Container Apps service — the runtime that hosts Logic Apps Standard in hybrid mode; all Logic App pods run as Container Apps on the Arc cluster |
| `Microsoft.Web` | Registers the Azure App Service / Logic Apps control plane — required for creating and managing the Logic App resource object in Azure and deploying workflow definitions via VS Code or Portal. Also hosts the run history, trigger history, and re-submission APIs for Logic Apps Standard (Standard does **not** use `Microsoft.Logic`) |

```bash
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.Web
```

> **Note:** `Microsoft.Logic` is **not required** for Logic Apps Standard hybrid. That namespace covers the old Consumption (multi-tenant) Logic Apps resource type (`Microsoft.Logic/workflows`). Logic Apps Standard runs as `Microsoft.Web/sites` (kind: workflowapp).

> Registration is asynchronous — each provider typically takes 1–3 minutes. Run the check below before proceeding to Step 5.

Check registration status (wait until all show `Registered`):

```bash
for ns in Microsoft.Kubernetes Microsoft.KubernetesConfiguration Microsoft.ExtendedLocation Microsoft.App Microsoft.Web; do
  echo -n "$ns: "
  az provider show -n $ns --query registrationState -o tsv
done
```

---

## 5. Onboard to Azure Arc

### 5.1 Set variables

```bash
RESOURCE_GROUP="rg-mw-ais-dev"          # adjust to MW Azure RG name
CLUSTER_NAME="arc-mw-ais-dev-k3s"
LOCATION="australiaeast"
NAMESPACE="logicapps-aca-ns"
CUSTOM_LOCATION_NAME="cl-mw-ais-dev"
CONNECTED_ENV_NAME="cae-mw-ais-dev"
```

> **Region note:** Australia East is confirmed supported by the MW Microsoft account manager. Use `australiaeast` throughout — do not change to another region.

### 5.2 Create resource group (if it doesn't exist)

```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5.3 Connect the cluster to Azure Arc

```bash
az connectedk8s connect \
  --name $CLUSTER_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

This deploys Arc agents into the `azure-arc` namespace on the K3s cluster. Takes 3–5 minutes.

> **Proxy note:** If using a proxy, add:
> ```
> --proxy-http http://<proxy>:<port> --proxy-https http://<proxy>:<port> --proxy-skip-range "localhost,127.0.0.1,10.0.0.0/8"
> ```

### 5.4 Verify Arc connection

```bash
az connectedk8s show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query connectivityStatus
```

Expected: `"Connected"`

Also check Arc agent pods:

```bash
kubectl get pods -n azure-arc
```

All pods should be `Running`.

---

## 6. Install Container Apps Arc Extension and SMB CSI Driver

Logic Apps Standard hybrid runs on the **Azure Container Apps on Arc** infrastructure — not the Functions Arc extension. This step installs the Container Apps extension, creates the custom location, provisions the connected environment, and deploys the SMB CSI driver (required for Logic Apps artifact storage).

### 6.1 Create the namespace

```bash
kubectl create namespace $NAMESPACE
```

### 6.2 Install the Container Apps extension on Arc

```bash
az k8s-extension create \
  --name aca-ext \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --cluster-type connectedClusters \
  --extension-type Microsoft.App.Environment \
  --release-namespace $NAMESPACE \
  --auto-upgrade-minor-version true \
  --configuration-settings "Microsoft.CustomLocation.ServiceAccount=default" \
  --configuration-settings "appsNamespace=$NAMESPACE" \
  --configuration-settings "clusterName=$CLUSTER_NAME" \
  --configuration-settings "keda.enabled=true"
```

Wait for the extension to provision (5–10 minutes):

```bash
az k8s-extension show \
  --name aca-ext \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --cluster-type connectedClusters \
  --query provisioningState
```

Expected: `"Succeeded"`

Verify extension pods in the namespace:

```bash
kubectl get pods -n $NAMESPACE
```

### 6.3 Get the extension resource ID

```bash
EXT_ID=$(az k8s-extension show \
  --name aca-ext \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --cluster-type connectedClusters \
  --query id -o tsv)

echo "Extension ID: $EXT_ID"
```

### 6.4 Create the custom location

```bash
CLUSTER_ID=$(az connectedk8s show \
  --name $CLUSTER_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

az customlocation create \
  --name $CUSTOM_LOCATION_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --host-resource-id $CLUSTER_ID \
  --namespace $NAMESPACE \
  --cluster-extension-ids $EXT_ID
```

Verify:

```bash
az customlocation show \
  --name $CUSTOM_LOCATION_NAME \
  --resource-group $RESOURCE_GROUP \
  --query provisioningState
```

Expected: `"Succeeded"`

### 6.5 Create the Container Apps connected environment

```bash
CUSTOM_LOCATION_ID=$(az customlocation show \
  --name $CUSTOM_LOCATION_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

az containerapp connected-env create \
  --name $CONNECTED_ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --custom-location $CUSTOM_LOCATION_ID
```

Verify:

```bash
az containerapp connected-env show \
  --name $CONNECTED_ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --query provisioningState
```

Expected: `"Succeeded"`

### 6.6 Install the SMB CSI driver

Logic Apps requires an SMB file share to store workflow artifacts (binaries and definition files). The SMB CSI driver lets K3s pods mount the Samba share configured in Step 7.

> **Network requirement — `raw.githubusercontent.com`:** The SMB CSI Helm chart repository is hosted at `https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts`. This is the same domain used to install Helm in step 4.5 — outbound TCP 443 to `raw.githubusercontent.com` must remain permitted.

```bash
helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts
helm repo update

helm install csi-driver-smb csi-driver-smb/csi-driver-smb \
  --namespace kube-system \
  --version v1.15.0
```

Verify the CSI driver is registered:

```bash
kubectl get csidrivers
```

Expected output includes:

```
NAME                    ATTACHREQUIRED   PODINFOONMOUNT   ...
smb.csi.k8s.io          false            false            ...
```

---

## 7. Configure Samba SMB File Share

Logic Apps hybrid requires an SMB file share for workflow artifact storage. For this POC, Samba runs on `svaisaksdev01` alongside K3s.

### 7.1 Install Samba

```bash
sudo dnf install -y samba samba-client samba-common
```

### 7.2 Create the share directory

```bash
sudo mkdir -p /mnt/logicapps-share
sudo chown nobody:nobody /mnt/logicapps-share
sudo chmod 0775 /mnt/logicapps-share
```

### 7.3 Set SELinux context for Samba

```bash
sudo setsebool -P samba_export_all_rw on
sudo restorecon -Rv /mnt/logicapps-share
```

### 7.4 Create a Samba user for Logic Apps

First create a Linux system account (no login shell), then set a Samba password:

```bash
sudo useradd -M -s /sbin/nologin logicapps-smb
sudo smbpasswd -a logicapps-smb
```

> Store the Samba password in **Azure Key Vault**. You will need it when creating the Logic App in Step 9.

### 7.5 Configure /etc/samba/smb.conf

Back up the existing config, then add the share definition:

```bash
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
```

Add the following block to the end of `/etc/samba/smb.conf`:

```ini
[logicapps]
   path = /mnt/logicapps-share
   valid users = logicapps-smb
   read only = no
   browseable = no
   create mask = 0664
   directory mask = 0775
```

Validate the configuration:

```bash
testparm
```

No syntax errors should be reported.

### 7.6 Enable and start Samba

```bash
sudo systemctl enable smb nmb
sudo systemctl start smb nmb
sudo systemctl status smb
```

### 7.7 Open firewall for K3s pod traffic to SMB

K3s pods need to reach the Samba service on the host. Allow SMB only from the K3s pod network — do not open SMB to the corporate network.

```bash
# K3S_POD_CIDR was set in Step 2.3 and persisted to ~/.bashrc
# If starting a new session, re-export it or substitute the value directly
source ~/.bashrc
echo "Applying SMB firewall rule for K3s pod CIDR: ${K3S_POD_CIDR}"

sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"${K3S_POD_CIDR}\" service name=\"samba\" accept"
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

> Verify the rule shows the CIDR you configured in Step 2.3, not a different range. If `K3S_POD_CIDR` is unset, run `kubectl get nodes -o jsonpath='{.items[0].spec.podCIDR}'` to retrieve the actual configured value from the cluster.

### 7.8 Verify the share is accessible

From the VM itself, test with the Samba client:

```bash
smbclient //localhost/logicapps -U logicapps-smb -c "ls"
```

Expected: directory listing with no errors.

### 7.9 Note the SMB connection details

You will need these values when creating the Logic App in Step 9:

```
SMB host name:   <svaisaksdev01 primary IP — NOT localhost>
File share path: logicapps
User name:       logicapps-smb
Password:        <samba password from Key Vault>
```

> Use the VM's primary IP address (e.g. `10.x.x.x`), **not** `localhost` or `127.0.0.1`. K3s pods cannot use the loopback interface to reach host services.

Confirm the VM's primary IP:

```bash
hostname -I | awk '{print $1}'
```

---

## 8. Configure SQL Server

SQL Server 2022 for Linux stores Logic Apps workflow state and run history. The Logic Apps runtime **automatically creates** the required schema (`dt`, `dq`, `dc`) and tables on first startup — you only need to create the database and a login with `db_owner` access.

### 8.1 Install SQL Server (if not already done)

```bash
sudo curl -o /etc/yum.repos.d/mssql-server.repo \
  https://packages.microsoft.com/config/rhel/9/mssql-server-2022.repo

sudo dnf install -y mssql-server

sudo /opt/mssql/bin/mssql-conf setup
```

When prompted:
- Edition: select **Developer** (free for dev/test — do not use Express, not available on Linux)
- SA password: set a strong password, store in **Azure Key Vault**

### 8.2 Enable and start SQL Server

```bash
sudo systemctl enable mssql-server
sudo systemctl start mssql-server
sudo systemctl status mssql-server
```

### 8.3 Install SQL command-line tools

```bash
sudo curl -o /etc/yum.repos.d/mssql-tools18.repo \
  https://packages.microsoft.com/config/rhel/9/prod.repo

sudo dnf install -y mssql-tools18 unixODBC-devel
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 8.4 Create the Logic Apps database and login

The Logic Apps runtime will create its own tables and schemas (`dt`, `dq`, `dc`) automatically when the runtime starts. You only need to create a blank database and a login with `db_owner` access.

```bash
sqlcmd -S localhost -U sa -P '<sa-password>' -Q "
CREATE DATABASE LogicAppsDB;
GO
CREATE LOGIN logicapps_user WITH PASSWORD = '<strong-password>';
GO
USE LogicAppsDB;
CREATE USER logicapps_user FOR LOGIN logicapps_user;
ALTER ROLE db_owner ADD MEMBER logicapps_user;
GO
"
```

> Store `logicapps_user` password in **Azure Key Vault**. You will also need it for the SQL connection string in Step 9.

> **Do not** pre-create tables or schemas. The runtime auto-provisions them on first start.

### 8.5 Restrict SQL Server firewall access

Allow only loopback and K3s pod network — block external access:

```bash
# K3S_POD_CIDR was set in Step 2.3 and persisted to ~/.bashrc
source ~/.bashrc
echo "Applying SQL firewall rule for K3s pod CIDR: ${K3S_POD_CIDR}"

sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="127.0.0.1" port port="1433" protocol="tcp" accept'
sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"${K3S_POD_CIDR}\" port port=\"1433\" protocol=\"tcp\" accept"
sudo firewall-cmd --reload
```

> Verify the CIDR in the rule matches what you configured in Step 2.3. To confirm the value currently active on the cluster: `kubectl get nodes -o jsonpath='{.items[0].spec.podCIDR}'`.

### 8.6 Note the SQL connection string

Logic Apps pods cannot use `localhost` to reach the SQL Server — use the VM's primary IP:

```
Server=<svaisaksdev01-IP>,1433;Database=LogicAppsDB;User Id=logicapps_user;Password=<password>;
```

Store this as a Kubernetes secret for reference:

```bash
kubectl create secret generic logicapps-sql-secret \
  --namespace $NAMESPACE \
  --from-literal=sql-connection-string="Server=$(hostname -I | awk '{print $1}'),1433;Database=LogicAppsDB;User Id=logicapps_user;Password=<password>;"
```

---

## 9. Create Logic App Hybrid Resource and Deploy a Workflow

Logic Apps hybrid cannot be created via the basic `az logicapp create` CLI command. Use the **Azure Portal** or **VS Code** with the hybrid hosting option selected.

### 9.1 Create the Logic App via Azure Portal

1. Go to [portal.azure.com](https://portal.azure.com) → **Create a resource** → search **Logic App** → select **Logic App** → **Create**
2. Fill in **Basics**:
   - Subscription: MW subscription
   - Resource Group: `rg-mw-ais-dev`
   - Logic App name: `la-mw-ais-dev-01`
   - Region: **Australia East**
   - Plan type: **Standard**
   - **Hosting option**: select **Hybrid** (not Workflow Standard)
3. On the **Hybrid** tab, fill in the required fields:

   | Field | Value |
   |---|---|
   | Container App Environment | Select `cae-mw-ais-dev` (created in Step 6.5) |
   | SQL connection string | `Server=<svaisaksdev01-IP>,1433;Database=LogicAppsDB;User Id=logicapps_user;Password=<password>;` |
   | SMB host name | `<svaisaksdev01 primary IP>` |
   | File share path | `logicapps` |
   | User name | `logicapps-smb` |
   | Password | `<samba password from CyberArk>` |

4. Complete the wizard and click **Review + create** → **Create**

> **Alternative — VS Code:** Install the **Azure Logic Apps (Standard)** extension in VS Code. When creating a new Logic App project, choose **Hybrid** as the hosting option. The extension will prompt for the same connected environment and storage details.

### 9.2 Verify the Logic App pod is running on-premises

After creation (allow 3–5 minutes for the pod to start):

```bash
kubectl get pods -n $NAMESPACE
```

You should see a pod named after your Logic App (`la-mw-ais-dev-01-...`) in `Running` state.

```bash
kubectl describe pod -n $NAMESPACE <pod-name>
```

Check the events section for any storage mount or connectivity errors.

### 9.3 Deploy a test workflow via VS Code

1. Open VS Code with the **Azure Logic Apps (Standard)** extension installed
2. In the Azure panel, navigate to your Logic App `la-mw-ais-dev-01`
3. Create a new workflow — choose **Stateful** (required for on-premises run history)
4. Add an **HTTP trigger** and a **Response** action
5. Deploy the workflow to the Logic App
6. Use the trigger URL to send a test HTTP request

### 9.4 Verify the Logic App runtime auto-created SQL schemas

After the first workflow run, confirm the runtime has initialised the database. The Logic Apps runtime creates schemas `dt`, `dq`, and `dc` automatically — do not create these manually.

```bash
sqlcmd -S localhost -U logicapps_user -P '<password>' \
  -d LogicAppsDB \
  -Q "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA IN ('dt','dq','dc') ORDER BY TABLE_SCHEMA, TABLE_NAME;"
```

Expected: a list of tables across the `dt`, `dq`, and `dc` schemas. An empty result means the runtime has not yet written run history — trigger a workflow run and re-check.

### 9.5 Verify data stays on-premises

Confirm run history is stored locally in SQL Server and not sent to Azure:

```bash
sqlcmd -S localhost -U logicapps_user -P '<password>' \
  -d LogicAppsDB \
  -Q "SELECT TOP 5 TABLE_SCHEMA, TABLE_NAME, (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=T.TABLE_SCHEMA AND TABLE_NAME=T.TABLE_NAME) AS ColCount FROM INFORMATION_SCHEMA.TABLES T WHERE TABLE_SCHEMA IN ('dt','dq') ORDER BY TABLE_SCHEMA, TABLE_NAME;"
```

---

## 10. Configure Entra App Registration for Managed Connectors

> **Note:** Managed identity is **not supported** for Logic Apps connectors running on Arc. You must create a Microsoft Entra app registration and provide the credentials as environment variables on the Logic App. This is required to use any managed connector (e.g. Service Bus, Storage, SharePoint, SQL via managed connector).

### 10.1 Create an Entra app registration

Via Azure CLI:

```bash
APP_NAME="sp-mw-ais-logicapps-dev"

az ad sp create-for-rbac \
  --name $APP_NAME \
  --skip-assignment \
  --output json
```

Record the output — you will need all four values:

```json
{
  "appId": "<WORKFLOWAPP_AAD_CLIENTID>",
  "displayName": "sp-mw-ais-logicapps-dev",
  "password": "<WORKFLOWAPP_AAD_CLIENTSECRET>",
  "tenant": "<WORKFLOWAPP_AAD_TENANTID>"
}
```

Retrieve the Object ID (different from appId):

```bash
az ad sp show --id <appId-from-above> --query id -o tsv
```

Store all four values in **Azure Key Vault**.

### 10.2 Grant the service principal the required permissions

Assign the service principal the roles it needs for the connectors you plan to use. For example, to use the Azure Service Bus connector:

```bash
az role assignment create \
  --assignee <appId> \
  --role "Azure Service Bus Data Owner" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.ServiceBus/namespaces/<namespace>"
```

Adjust the role and scope for each connector your workflows use.

### 10.3 Store and reference credentials as Container Apps secrets

Logic Apps hybrid runs on Container Apps on Arc. Sensitive values must be stored as **Container Apps secrets** and referenced by name in environment variables — this prevents raw values appearing in the Azure Portal UI and ARM API responses.

> **Important — portal navigation for hybrid Logic Apps:** A hybrid Logic App exposes the Container Apps model in its Settings menu: **Secrets**, **Containers**, and **Revisions and replicas**. If you see a classic **Configuration** blade instead, the resource was not created as hybrid — verify before proceeding.

> **Why not Key Vault references?** Container Apps Key Vault secret references require managed identity on the container app. Managed identity is [explicitly unavailable on Container Apps on Azure Arc](https://learn.microsoft.com/en-us/azure/container-apps/azure-arc-overview#limitations). Azure Key Vault is used as the **authoritative source of truth** — values are retrieved from Key Vault and loaded into Container Apps secrets at setup and rotation time.

#### Part A — Store all secrets in Azure Key Vault

```bash
az keyvault secret set --vault-name <kv-name> --name "logicapps-aad-clientid"          --value "<appId>"
az keyvault secret set --vault-name <kv-name> --name "logicapps-aad-clientsecret"      --value "<client-secret>"
az keyvault secret set --vault-name <kv-name> --name "logicapps-sql-connectionstring"  --value "Server=<ip>,1433;Database=LogicAppsDB;User Id=logicapps_user;Password=<password>;"
az keyvault secret set --vault-name <kv-name> --name "logicapps-smb-password"          --value "<samba-password>"
```

#### Part B — Create Container Apps secrets on the Logic App

In Azure Portal, navigate to your Logic App `la-mw-ais-dev-01` → **Settings** → **Secrets** → **Add**.

Retrieve each value from Key Vault first:

```bash
az keyvault secret show --vault-name <kv-name> --name <secret-name> --query value -o tsv
```

Add each secret:

| Secret name | Value source |
|---|---|
| `workflowapp-aad-clientid` | `logicapps-aad-clientid` from Key Vault |
| `workflowapp-aad-clientsecret` | `logicapps-aad-clientsecret` from Key Vault |
| `sql-connection-string` | `logicapps-sql-connectionstring` from Key Vault |
| `smb-password` | `logicapps-smb-password` from Key Vault |

> Secret names on Container Apps must be **lowercase with hyphens only** — no underscores or uppercase. The portal enforces this constraint.

#### Part C — Reference secrets in environment variables

Navigate to **Settings** → **Containers** → **Edit and deploy** → **Environment variables** tab → **Add**.

Set **Source** to **Reference a secret** for all sensitive values. `WORKFLOWAPP_AAD_OBJECTID` and `WORKFLOWAPP_AAD_TENANTID` are non-sensitive GUIDs — set these as **Manual entry**.

| Name | Source | Secret name / Value |
|---|---|---|
| `WORKFLOWAPP_AAD_CLIENTID` | Reference a secret | `workflowapp-aad-clientid` |
| `WORKFLOWAPP_AAD_CLIENTSECRET` | Reference a secret | `workflowapp-aad-clientsecret` |
| `Workflows.Sql.ConnectionString` | Reference a secret | `sql-connection-string` |
| `WEBSITE_SMB_SERVER_PASSWORD` | Reference a secret | `smb-password` |
| `WORKFLOWAPP_AAD_OBJECTID` | Manual entry | `<Object ID>` |
| `WORKFLOWAPP_AAD_TENANTID` | Manual entry | `<tenantId>` |

Select **Save** — this creates a new Container Apps revision and restarts the pod.

> **Note — storage credentials set during creation:** The SQL connection string and SMB password entered in the portal creation wizard (Step 9.1) are initially stored as plain env vars. This step replaces them with secret references. Ensure the values in `sql-connection-string` and `smb-password` match exactly what was entered in the wizard.

### 10.4 Verify the pod picks up the new settings

```bash
kubectl get pods -n $NAMESPACE
```

A new pod should be `Running` after the save. Check the pod logs for any authentication errors:

```bash
kubectl logs -n $NAMESPACE <new-pod-name> --tail=50
```

---

## 11. Operational Notes

### Checking K3s status

```bash
sudo systemctl status k3s
kubectl get nodes
kubectl get pods -A
```

### Checking Arc agent health

```bash
kubectl get pods -n azure-arc
az connectedk8s show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query connectivityStatus
```

### Checking Logic Apps and Container Apps pods

```bash
kubectl get pods -n $NAMESPACE
kubectl logs -n $NAMESPACE <pod-name> --tail=100
```

### Checking Samba status

```bash
sudo systemctl status smb nmb
smbstatus --shares
```

### Checking SQL Server status

```bash
sudo systemctl status mssql-server
sqlcmd -S localhost -U logicapps_user -P '<password>' -Q "SELECT @@VERSION;"
```

### K3s logs

```bash
sudo journalctl -u k3s -f
```

### Restarting K3s

```bash
sudo systemctl restart k3s
```

> All pods restart automatically. Logic Apps resumes processing after pod readiness (typically 30–60 seconds).

### Rotating the Entra app registration secret

When the `WORKFLOWAPP_AAD_CLIENTSECRET` expires:

1. Generate a new client secret in Entra ID → **App registrations** → `sp-mw-ais-logicapps-dev` → **Certificates & secrets**
2. Update the secret in Azure Key Vault:
   ```bash
   az keyvault secret set --vault-name <kv-name> --name "logicapps-aad-clientsecret" --value "<new-secret>"
   ```
3. Update the Container Apps secret on the Logic App: Portal → **Settings → Secrets** → select `workflowapp-aad-clientsecret` → update value → **Save**
4. Go to **Settings → Revisions and replicas** → restart the active revision to pick up the new value

### Upgrading K3s

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.33.x+k3s1 sh -
```

Always check the [K3s release notes](https://github.com/k3s-io/k3s/releases) and the [Azure Arc validated versions](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/validation-program) before upgrading.

### Arc extension upgrade

The Container Apps extension auto-upgrades when `--auto-upgrade-minor-version true` is set. To check current version:

```bash
az k8s-extension show \
  --name aca-ext \
  --cluster-name $CLUSTER_NAME \
  --resource-group $RESOURCE_GROUP \
  --cluster-type connectedClusters \
  --query "{version:version, state:provisioningState}"
```

### 24-hour disconnected operation limit

Logic Apps hybrid can operate disconnected from Azure for up to **24 hours**. Beyond 24 hours:
- Workflow execution continues locally
- Logging data (run history beyond the 24-hour window) may be lost
- Workflow definitions and configurations remain intact

Ensure ExpressRoute is monitored and alerts are set for connectivity loss. Restore connectivity within 24 hours to prevent log data loss.

### Useful reference links

| Resource | URL |
|---|---|
| K3s documentation | https://docs.k3s.io |
| Azure Arc-enabled Kubernetes | https://learn.microsoft.com/azure/azure-arc/kubernetes |
| Arc validated distributions (K3s listed) | https://learn.microsoft.com/azure/azure-arc/kubernetes/validation-program |
| Logic Apps hybrid overview | https://learn.microsoft.com/azure/logic-apps/azure-arc-enabled-logic-apps-overview |
| Logic Apps hybrid create and deploy | https://learn.microsoft.com/azure/logic-apps/azure-arc-enabled-logic-apps-create-deploy-workflows |
| Container Apps on Arc | https://learn.microsoft.com/azure/container-apps/azure-arc-enable |
| SQL Server 2022 on RHEL | https://learn.microsoft.com/sql/linux/quickstart-install-connect-red-hat |
| SMB CSI driver | https://github.com/kubernetes-csi/csi-driver-smb |

---

*This runbook is for the dev/POC environment only (`svaisaksdev01`). Production deployment will require a 3-node K3s HA cluster, Samba on dedicated storage, and additional hardening steps.*
