# Architecture: BizTalk → AIS Component Map

For each row: what BizTalk does today, what replaces it in AIS, and **why** that
replacement is the right fit for Melbourne Water.

> **Note on evidence**: rows below describe standard BizTalk 2016 components.
> Specific MW usage of pipelines, maps, MessageBox correlation, and ESB Toolkit
> is **inferred from typical BizTalk deployments and not yet evidenced in the
> source CSVs/docs supplied**. See [07-questionnaire.md](07-questionnaire.md)
> for SME validation questions.

## Component map

### 1. Receive Locations & Send Ports → Logic Apps Standard triggers & actions
**BizTalk today:** Receive Locations are endpoint listeners (HTTP/SOAP, file
folder, MSMQ, SQL polling) bound to Receive Ports. Send Ports are the outbound
counterparts that push messages to a destination after subscription filters
match — e.g. file pickup feeding `MW.MaximoKronos`, or the SOAP listener
fronting `MW.DSSCon.PegaESRIIntegration.*`.

**AIS replacement:** Logic Apps Standard **triggers** (HTTP, Service Bus, Blob,
Schedule, SFTP, on-prem data gateway) and **actions** (HTTP, Service Bus send,
file write).

**Why:** 1:1 conceptual replacement, but declarative, version-controlled in
git, deployed via Bicep — no GAC, no host instances, no XML binding files.
Logic Apps Standard runs on the Functions runtime, giving **per-workflow
scaling and isolation** instead of BizTalk's shared host-instance model where
one noisy integration starves others on SVBTSPROD01–04.

### 2. Orchestrations → Stateful Logic App workflows
**BizTalk today:** XLANG/s state machines compiled to .NET assemblies, stored
in the BizTalk MessageBox SQL DB. Handle long-running flows with persistence,
dehydration, correlation, compensation, parallel shapes — e.g. the Pega→ESRI
flows in `08-DevConnect`.

**AIS replacement:** **Stateful Logic Apps** (workflow definition language).

**Why:** Same durability guarantees (run history, retry, dehydration on long
waits) without SQL Server MessageBox infrastructure. State is managed in Azure
Storage tables — no DBA maintenance, no MessageBox growth issues. Visual
designer + JSON definition give both diagrams (for stakeholder workshops) and
proper PR diffs. **Stateless** variant exists for sub-second pass-throughs.

### 3. WCF Routers (SVBZWEBPROD01/02) → API Management Premium (internal VNet)
**BizTalk today:** Two DMZ servers running custom WCF routing components
("Virtual Endpoints" + "Message Filters") behind Citrix NetScaler. They
terminate external SOAP/REST calls from Pega, TechOne, Zycus, Programmed,
hide internal BizTalk URLs, and apply basic message filtering before
forwarding into the core network through the internal firewall.

**AIS replacement:** **APIM Premium** in **internal VNet mode**, with
self-hosted gateway option for on-prem callers if needed during transition.

**Why:**
- The "virtual endpoint + filter" pattern *is* the APIM model — versioning,
  revisions, products, subscriptions, developer portal native
- **Premium tier** mandatory: only SKU with VNet integration, multi-region,
  availability zones — replacing active/active SVBZWEBPROD01/02 with managed
  equivalent
- Policies (XML, executed inline) replace bespoke C# routing code: rate
  limiting, JWT validation, request/response transformation, IP filtering
- Decommissions two physical servers + NetScaler routing rules in one move

### 4. Pipelines & Maps → Logic App `compose` + Liquid/XSLT, or Azure Functions
**BizTalk today:** Pipelines are ordered stages (decode, disassemble,
validate, resolve party, encode) of pipeline components. Maps are BizTalk
Mapper `.btm` files compiled to XSLT 1.0 with .NET helper assemblies for
complex logic — heavily used in DevConnect cleansing, CAD business rules,
Procurement transformations.

**AIS replacement:** Two-tier strategy:
- **Simple transforms** → Logic App built-in actions: `compose`, `parse JSON`,
  **Liquid templates** (best fit for JSON), or **XSLT 3.0** transform action
  (legacy XML)
- **Complex transforms / business rules** → **Azure Functions** (.NET 8 for
  direct port of BizTalk helper assemblies, Python for new logic)

**Why:** Liquid + XSLT 3.0 cover ~70% of BizTalk maps with a 1:1 port. The
remaining 30% (anything with .NET helper code, BRE policies, or BAM tracking)
goes to Functions where you get unit-testable code, dependency injection, and
proper CI/CD. The .NET engineer's existing skills transfer directly. The
split also **decouples transformation from orchestration**, which BizTalk
conflates and which makes current code hard to test in isolation.

### 5. MessageBox + Correlation → Service Bus Premium (queues, topics, sessions)
**BizTalk today:** Central SQL Server database every message flows through.
Provides publish/subscribe, durable storage, correlation set matching for
multi-message orchestrations, ordered delivery. Single biggest operational
headache — backups, growth, locking, and the SQL cluster is on the critical
path for every integration.

**AIS replacement:** **Service Bus Premium** namespace.
- **Queues** for point-to-point durable handoff
- **Topics + subscriptions** for the pub/sub pattern BizTalk uses internally
- **Sessions** for FIFO + correlation (replaces correlation sets — `SessionId`
  is the correlation token)
- **Dead-letter queues** for poison messages (replaces BizTalk suspended queue)

**Why:**
- Removes SQL MessageBox single point of failure and DBA burden
- Premium gives VNet integration, dedicated capacity, predictable latency
- Sessions are a clean replacement for correlation sets — cheaper to reason
  about than BizTalk's promoted-properties model
- Native auto-forwarding + duplicate detection cover patterns BizTalk needed
  custom orchestrations for
- Plays naturally with Logic Apps (first-class trigger) and APIM (publish
  via policy)

### 6. File Adapter → Storage Blob trigger / Azure Files / SFTP via Logic App
**BizTalk today:** File adapter polls a folder on a file share (most "Daily
based on file placed event" integrations: PageUp-Chris21, P3I-Maximo, AMIS-Q4,
Liquid-Inflo, IDAM-Chris21). Polling interval, batch size, rename-on-pickup
configured per receive location.

**AIS replacement:**
- **Storage Blob** with event-driven trigger — preferred for new integrations
- **Azure Files** SMB share — drop-in replacement when on-prem systems can't
  change drop location
- **SFTP** trigger — for partners that already SFTP today

**Why:** Event-driven beats polling — no missed files, no overlapping runs,
no "is the file fully written?" race condition (Storage events fire on close).
Storage Lifecycle Management auto-archives processed files, replacing the
bespoke "move to archive folder" pipeline component most file integrations
use today. Crucially: **AMIS Q4 and similar can keep the same on-prem drop
folder** via Azure Files mount, so the upstream system doesn't change.

### 7. BAM (Business Activity Monitoring) → Application Insights + Log Analytics
**BizTalk today:** BAM lets you instrument orchestrations to track
business-level events (e.g. Invoice received → Approved → Paid) into a SQL
Analysis cube. In practice MW likely uses sparingly because it requires
schema changes and DBA work for every new tracked field.

**AIS replacement:** **Application Insights** custom events + **Log
Analytics** workspace with KQL workbooks.

**Why:** Emit a custom event from a Logic App action (`trackEvent`) with
arbitrary properties — no schema migration, no cube rebuild. KQL gives
cross-integration correlation (one query across all 67 integrations) which
BAM never could. Workbooks replace the BAM portal with shareable,
parameterised dashboards.

### 8. BizTalk360 (SVBTSPROD05) → Azure Monitor + Workbooks + Service Health
**BizTalk today:** Third-party tool on a dedicated server providing alerting,
throttling analysis, dashboards, and operational automation across the
BizTalk farm. Licensed annually.

**AIS replacement:** **Azure Monitor** (alerts, action groups), **Azure
Workbooks** (dashboards), **Service Health** (platform status), Logic Apps
for any auto-remediation actions.

**Why:** Azure Monitor included with the platform — no separate licence.
Alerts are richer (KQL-based vs threshold-based) and integrate with on-call
tooling (PagerDuty, Teams, ServiceNow) out of the box. SVBTSPROD05 is
decommissioned. **Alert-parity matrix** built in Wave 1 so every BizTalk360
alert has a documented Azure Monitor equivalent before first cutover.

### 9. ESB Toolkit Itineraries → APIM policies + Logic App workflow chaining
**BizTalk today:** ESB Toolkit (`Microsoft.Practices.ESB` in `18-BizTalk`)
provides itinerary-based routing — define a sequence of services to call in
a config file, toolkit dispatches messages through them. Used lightly at MW
for some Pega→ESRI flows.

**AIS replacement:** **APIM policies** for routing/transformation steps;
**Logic App workflow chaining** (one workflow calls the next via HTTP or
Service Bus) for true itinerary semantics.

**Why:** ESB Toolkit is essentially unmaintained; "config-driven routing"
rarely paid off — most teams hard-code the itinerary anyway. APIM policies
+ Logic Apps give the same composition, in code, with proper testing and
observability. The itinerary becomes a workflow definition you can diff
and review.

### 10. Common Components/Schemas → Shared Logic App library + git schema repo
**BizTalk today:** `MW.BizTalk.Common.Components` and `MW.BizTalk.Common.Schemas`
plus app-specific `MW.*.Common` projects (Procurement, Zycus, P3I, AMIS,
Kronos) — shared C# helpers and XSD schemas referenced by every integration.
Updating one means redeploying every dependent app.

**AIS replacement:**
- **Shared Logic App workflow library** — reusable workflows in a dedicated
  Logic App Standard project, called via HTTP or workflow-to-workflow invoke
- **Git-versioned schema repo** — JSON Schema + XSD, published as an npm/NuGet
  package consumed by integration repos

**Why:** Versioning becomes explicit (semver) instead of "everything redeploys
together". Breaking changes are visible in PRs. Each integration pins the
version of common it uses, so you can roll forward independently — directly
addresses the deployment-coupling pain that makes current BizTalk releases
slow and risky.

### 11. Hosts (cross-cutting) → Managed runtime
**BizTalk today:** Host instances on SVBTSPROD01–04 (typically split into
Receive, Send, Processing, Tracking hosts) — manually balance which
orchestrations run where; a single bad message can throttle a whole host.

**AIS replacement:** Logic Apps Standard plan + APIM Premium units + Service
Bus Premium messaging units — all **managed compute**, all **per-workflow
scaling**.

**Why:** No more host tuning, no more "Processing host throttled, restart it".
Each Logic App can have its own scale settings; noisy neighbours are isolated
by design. Reduces operational toil currently consuming meaningful share of
the 2 engineers' time.

## Topology

- **Ingress:** Cloudflare → Azure Front Door (optional) → APIM (internal mode) on VNet
- **Hybrid connectivity:** ExpressRoute already in place; on-prem callouts via
  APIM self-hosted gateway *or* Logic App on-prem data gateway depending on
  protocol
- **Cloud-to-cloud:** APIM front, Logic App backend, managed identity to SaaS
  (Pega, Zycus, PageUp, TechOne, Project Online)
- **Async/durable:** Service Bus Premium for retry, dead-letter, ordered
  processing (replaces MessageBox guarantees)
- **Secrets/config:** Key Vault references in Logic Apps, no inline credentials
- **Observability:** every workflow emits correlation ID; Log Analytics
  workspace shared; Application Insights per Logic App; alerts pipe to
  existing on-call tooling

## Skill split for transformation work

- **Python engineer:** Azure Functions for complex transforms, custom APIM
  policies tooling, migration scripts, ETL-style transforms
- **.NET engineer:** Port BizTalk pipeline-component logic where rewrite is
  required (DevConnect cleansing, CAD business rules)

## Naming conventions (per Microsoft guidance)

- Logic App resource: `LAStd-MW-<app>-<env>` (e.g. `LAStd-MW-Maximo-PROD`)
- Workflow: `Process-<name>` (e.g. `Process-MaximoAttachment`)
- Operations: Pascal-hyphen (e.g. `Parse-JSON-AttachmentPayload`) — avoid spaces
- Connections: `CN-<connector>-<workflow>` (e.g. `CN-ServiceBus-MaximoAttachment`)
