# Change Request Template

Use this template when raising change requests for SOC infrastructure changes.

---

## Business Impact
_Mention the potential impact to business users and systems during and after the change. (2-3 sentences)_

During the change, [service/system] may be temporarily unavailable/degraded while [brief description of what's happening], potentially causing [impact e.g. gap in log visibility, service interruption]. After the change, [expected steady-state outcome] and no end-user impact is expected.

---

## Technical Impact
_Mention the technical details of what CI is being changed and what are the downstream and upstream applications/CIs impacted by it. (2-3 sentences)_

The [CI being changed, e.g. API credentials, infrastructure component, connector config] is being modified/provisioned. Upstream: [upstream systems, e.g. data source API, Cloudflare Logpush]. Downstream: [downstream systems, e.g. Azure Function App, Sentinel Log Analytics workspace, DCR pipeline].

---

## What is being Changed?
_Brief description of the specific change being made._

[e.g. Provisioning new storage bucket and generating API credentials to enable programmatic access for log data ingestion.]

---

## Why are we performing the Change?
_Business or technical justification._

[e.g. To enable S3-compatible access to a new data source, allowing the SOC log ingestion pipeline to retrieve security logs via a standard API.]

---

## What is the expected outcome?
_What success looks like._

[e.g. A functioning integration verified by a successful end-to-end test, with logs appearing in the target Sentinel table within the expected timer cycle.]

---

## Implementation Plan
1. [Provision/configure the resource in the source platform]
2. [Generate and securely store credentials]
3. [Store secrets in Azure Key Vault (`kv-devtest-ase-soc-01` for dev / `kv-prd-ase-soc-01` for prod)]
4. [Update Function App configuration (`appsettings-dev.json` / `appsettings-prod.json`) with Key Vault references]
5. [Run validation test in dev environment]
6. [Verify data flow: source → blob storage → Sentinel DCR → Log Analytics table]
7. [Promote to prod after dev validation passes]

---

## Backout Plan
1. [Revoke/disable new credentials or API tokens]
2. [Revert Function App configuration to previous values (restore from Git)]
3. [Confirm the previous pipeline resumes normal operation]
4. [Clean up any provisioned resources if no longer needed]

---

## PVT (Post-Verification Testing)
1. [Verify connectivity: authenticate and perform a basic read/write test]
2. [Verify data flow: confirm events arrive at the expected Sentinel `*_CL` table]
3. [Verify timing: confirm ingestion occurs within the expected timer schedule]
4. [Verify no errors in Function App logs (`FunctionAppLogs` in Log Analytics)]
