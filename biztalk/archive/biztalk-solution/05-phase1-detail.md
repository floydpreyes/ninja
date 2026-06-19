# Phase 1 (Wave 1) — Pilot Detail

Three pilot interfaces marked Phase 1 in the source CSV. Each proves a pattern
that the rest of the programme reuses. Outputs become the templates for Waves
2 and 3.

## Pilot 1 — `MW.Mobility.Maximo.Attachment` (~10 days)

**Pattern proved:** On-prem API ↔ on-prem API via Logic App with on-prem data
gateway

**Discovery (1–2 days):**
- Capture current WCF contract from SVBZWEBPROD01
- Maximo endpoint config + auth method
- Message size profile, peak TPS, attachment payload format
- Confirm with Maximo owner (Jawwad Saleem)

**Build (4–5 days):**
- Logic App Standard workflow + on-prem data gateway connection
- Service Bus queue for retry/DLQ
- Key Vault for Maximo creds (managed identity)
- APIM API definition fronting the Logic App

**Test (2–3 days):**
- Contract tests against Maximo non-prod
- Parallel run via BizTalk routing duplicate (BizTalk and Logic App both
  receive, only BizTalk delivers)
- Reconciliation: count + payload comparison

**Cutover:**
- APIM backend swap from BizTalk WCF to Logic App
- Single config change; instant rollback by reverting the policy

**Why it's first:** Lowest stakeholder complexity (single owner), proves
hybrid connectivity, validates APIM-as-cutover-mechanism.

## Pilot 2 — `MW.DSSCon.PegaESRIIntegration.DrainageInfo` (~15 days)

**Pattern proved:** HYBRID rewrite of Pega → ESRI API integration. This pattern
recurs across DevConnect (12), Incentive (5), CAD (2) — so a successful pilot
de-risks ~19 downstream integrations.

**Discovery (3–4 days):**
- Extract pipeline-component logic, business rules, message flow from
  current orchestration
- Engage Vijaya Bhaskara / Bianca Talarico (Pega) and Judy Johny (ESRI)
- Source repo audit for `MW.DSSCon.PegaESRIIntegration.*` projects
- aimbiztalk run on the DevConnect application

**Build (6–8 days):**
- Rewrite cleansing/business rules in .NET Azure Function (port from
  BizTalk helper assemblies)
- Logic App workflow for orchestration
- APIM policies preserve Pega-side contract (no Pega-side change required)
- Service Bus topic for any pub/sub patterns extracted from orchestration

**Test (3–4 days):**
- Shadow traffic 2 weeks
- Compare ESRI write payloads byte-for-byte
- Edge case replay: drainage info request types from prod logs

**Cutover:**
- APIM traffic split: 10% → 50% → 100% over 1 week
- Both backends stay live; rollback = revert traffic split

**Why it's second:** Proves the most expensive pattern (HYBRID rewrite) on the
single CSV-marked Phase 1 interface, so we get pattern-template benefits for
Waves 2 and 3.

## Pilot 3 — `MW.AMIS.Q4` (~5 days)

**Pattern proved:** Scheduled file-pickup batch. Recurs across PageUp-Chris21,
P3I-Maximo, Liquid-Inflo, IDAM-Chris21, MaximoKronos.

**Discovery (1 day):**
- File location, schema, error-handling rules, downstream Q4 ingestion
- Naming convention, archive policy, retention

**Build (2 days):**
- Storage Blob (or SFTP) trigger → Logic App → Q4 endpoint
- Schema validation pulled from new shared schema repo (built incrementally
  starting here)
- Lifecycle Management rules for archive

**Test (1 day):**
- Replay 30 days of historical files in non-prod
- Reconciliation report (file count, row count, payload hash)

**Cutover:**
- BizTalk receive location disabled
- AIS picks up from same drop folder (Azure Files mount keeps upstream
  systems unchanged)

**Why it's third:** Simplest pattern, but adopting the shared schema repo
here lets us validate the repo design before Wave 2 expands it.

## Common Phase 1 deliverables

These outputs are explicit success criteria for Wave 1 — without them, Wave 2
cannot benefit from template reuse.

### Reusable Bicep compositions (built on existing AVM modules)
- `apim-api` — APIM API + product + policy fragments
- `logicapp-standard-app` — Logic App + plan + storage + Key Vault refs
- `service-bus-queue` / `service-bus-topic`
- `storage-fileshare` — for Azure Files mount pattern

### Pipeline templates (clone existing MW DevOps patterns)
- PR validation
- Infra deploy (with Bicep `what-if`)
- Logic App workflow deploy
- Smoke tests
- Contract tests

### Pattern documentation
- `pattern-hybrid-api.md`
- `pattern-hybrid-rewrite.md`
- `pattern-file-batch.md`
- `pattern-cloud-cloud-api.md` (built in Wave 2; placeholder created in W1)

### Cutover runbook templates
Per Microsoft guidance:
- Prerequisites
- Dress rehearsal
- People + comms plan
- Schedule estimates
- Disable BizTalk interface
- Enable AIS interface
- Validation testing
- Rollback steps
- Go / no-go criteria

### Monitoring workbooks
- Per-integration KPI workbook (transactions, errors, latency, DLQ depth)
- Cross-integration health workbook (replaces BizTalk360 dashboard view)
- Alert parity matrix vs current BizTalk360 alerts (living document)

## Wave 1 exit criteria

Before Wave 2 starts:
- All three pilots in production with 30 days of clean operation
- All four pattern docs published
- All Bicep compositions in MW's shared module catalogue
- All pipeline templates clonable from MW DevOps
- Cutover runbook template validated against three real cutovers
- Alert parity matrix covers all three pilots
- Phase 1 retro complete; learnings folded into Wave 2 plan
