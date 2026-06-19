# WTP Birdwatching — Operations API & SQL Database Kickoff Discussion Pack

**Purpose:** Align the mobile lead and integration developer on the Operations API contract and SQL schema so both streams can start building in parallel, with auth delegated to Entra External ID and enforced at APIM (Operations API stays auth-provider agnostic).

**Date:** 18 June 2026
**Context:** Scenario B (Entra External ID) greenlit. No Identity API will be built; auth is enforced at APIM.

---

## Meeting objective

Align the mobile lead and integration developer on the **Operations API contract** and **SQL schema** so both streams can start building in parallel, with auth delegated to Entra External ID and enforced at APIM (Operations API stays auth-provider agnostic).

Attendees and what each owns going in:

- **You / AIS (integration dev)** — Operations API, SQL schema, APIM policies, infra (Bicep), CI/CD.
- **Mobile lead (Web Dev)** — MSAL integration, token acquisition, API consumption contract.
- Decision: confirm whether the **operator web app backend** is in scope for this same Operations API (it is, per SAD §6.1.1) so admin endpoints are designed up front.

---

## 1. The single most important design point: identity-to-data binding

The v0.2 schema still keys every table on `UserId INT NOT NULL` referencing a local `Users` table — but **in Scenario B there is no `Users` table** (auth tables are explicitly not created, per the delivery plan). This is the first thing to resolve.

**Validate / decide:**

- The user key in every operational table becomes the **Entra External ID Object ID (OID)** — a GUID delivered in the token (`oid` / `sub` claim). Per the Entra guide: *"Each user has a stable Object ID (OID) — this is the key used to link the user to their data."*
- Change `UserId INT` → `UserOid UNIQUEIDENTIFIER` (or `NVARCHAR(64)`) across `Permits`, `Visits`, `BirdSightings`, `Hazards`.
- Decide which claim is authoritative — confirm whether you key on `oid` or `sub`. For CIAM/External ID these can differ; pin one and document it.
- **Do you still need a lightweight `UserProfile` table?** External ID holds auth + display name/email, but you'll likely want an app-side profile row (vehicle rego, preferred area — from the old `UserProfiles`) keyed on OID, populated lazily on first authenticated call ("just-in-time provisioning"). Decide the JIT-create trigger.
- **Two different token issuers:** public birdwatchers come from the **External ID tenant** (`melbwaterext`), operators come from the **internal MW Entra tenant**. `PermitApprovals.ApproverId` must store the operator's OID from a *different* issuer. Confirm the API can distinguish caller type (via APIM product / claim) — don't conflate the two ID spaces.

---

## 2. SQL database design — validation checklist

- **Schema completeness:** the delivery plan lists tables for permits, visits, sightings, hazards, **tours, locks, notifications** — but v0.2 only shows DDL for the first set. Agree the full table list and draft DDL for tours, lock entitlement/audit, and notification targeting (device registration mapping OID → Notification Hub tags).
- **Keys & types:** OID as user key (above); consistent `DATETIME2` UTC; decide INT vs `BIGINT`/GUID surrogate keys for `Id`.
- **Referential integrity & state:** `Permits.Status` and `PermitApprovals` model the state machine `Draft → Submitted → UnderReview → Approved/Rejected/InfoRequested → Active → Expired`. Validate enforcement — DB check constraints vs application-layer only.
- **Lock entitlement rule:** "lock operations require permit ownership and active validity window" — decide where enforced (API query joining Permits validity) and what's audited.
- **Notification device registry:** new table needed to map user OID → device handle / Notification Hub installation, since registration moves to the app.
- **Migrations approach:** pipeline-executed scripts (per Deployment View). Pick the tool now — EF Core migrations, DbUp, Flyway, or raw SQL — so it's consistent from day one.
- **Access pattern:** Managed Identity from App Service → SQL over **private endpoint**, no connection-string secrets in app config (Key Vault reference only). Confirm SQL firewall = private endpoint only, TDE on.
- **PII / data classification:** doc is Official Sensitive. Tag PII columns; confirm with Cyber what's retained vs delegated to External ID (you should store *no* passwords/credentials at all).

---

## 3. Operations API design — validation checklist

- **Auth-agnostic contract:** API trusts APIM-validated JWT; it extracts caller OID + roles from forwarded claims, never validates tokens itself. Confirm how claims reach the API (APIM passes through `Authorization`, or injects validated claims as headers).
- **Endpoint surface** vs APIM routing table — lock the resource paths now so mobile can mock against them: `/api/permits`, `/api/visits`, `/api/birds`, `/api/hazards`, `/api/tours`, `/api/locks`, `/api/notifications`, `/api/content`, plus admin endpoints.
- **OpenAPI contract first:** each team owns and publishes its OpenAPI spec to the APIM portal (per SAD §6.1.3). Produce a draft spec in this meeting so the **mobile team can build against mocks / mock bearer tokens** immediately — this is exactly the Stream A integration approach (mock tokens, replaced with real External ID tokens when Stream B lands).
- **Authorization model inside the API:** APIM validates the token; the API still enforces *resource ownership* (a user can only see their own permits) and *role gates* (only `WTP.Operator`/`WTP.Admin` can transition review states). Decide role-claim source (app roles from internal tenant for operators).
- **Runtime stack:** .NET 8 vs Node — pick one (affects mobile only via contract, but affects your build).
- **Idempotency & offline:** mobile-first with intermittent connectivity — discuss idempotency keys for check-in/sighting submission and conflict handling.
- **Error contract:** standard error shape (RFC 7807 / problem+json) so mobile handles failures consistently.

---

## 4. APIM / auth wiring (Stream B touchpoints to pre-agree)

- **`validate-jwt` config values** the API design depends on:
  - Issuer: `https://melbwaterext.ciamlogin.com/<tenant-id>/v2.0`
  - Audience: `api://birdwatcher` (Application ID URI) — confirm app vs client ID as audience.
  - Scope: `api.access`; signing RS256 via OIDC discovery (no Key Vault signing key needed).
- **Public vs Admin products** = two policies, two issuers (External ID for public, internal MW Entra for operators). Confirm both now so the API's role/claim expectations match.
- **Redirect URI / bundle ID** the mobile lead must confirm: `msauth://com.melbournewater.birdwatcher/callback` — this is a hard dependency for the External ID app registration. Get the real iOS bundle ID / Android package name in the meeting.
- Pre-populate the OIDC metadata URL in APIM even before the tenant is live (tenant name is known), so there's zero rework when External ID is provisioned.

---

## 5. Mobile integration points to confirm with the lead

- MSAL config: authority, client ID, scope (`api://birdwatcher/api.access`), PKCE (Auth Code + PKCE for public/native client).
- Token handling: silent refresh, token storage, 401 → re-auth flow.
- **Device push registration:** app registers device → which endpoint, what gets stored (OID → device handle). Shapes your notification table.
- Bluetooth/Gallagher lock flow — what the app sends, what the API returns (protocol still TBD with Gallagher; flag as open).
- Agreement to build against **mocked API + mock JWT** until Stream B is ready (unblocks both teams immediately).

---

## 6. Infrastructure & "what to start building now" (Stream A)

All of this is independent of External ID availability — you can start once SAD is signed off:

1. **Bicep IaC** — VNet/subnets, NSGs, Azure Firewall rules, APIM (Standard v2, internal mode), reuse existing EP1 App Service plans, Azure SQL + private endpoint, Key Vault, App Insights/Log Analytics.
2. **SQL schema** (data tables only — no auth tables) + chosen migration tooling.
3. **Operations API** scaffold + OpenAPI + the domain endpoints.
4. **APIM** routing, rate-limiting, Named Values, placeholder `validate-jwt`.
5. **CI/CD** pipelines (no Identity API pipeline).
6. **Notification Hubs** (shared-services namespace, dev/prod hubs).
7. **Border firewall CR** — flag as the **critical-path dependency** (2–4 week lead, submit same day as SAD sign-off). Not a code task but it gates network testing.

---

## 7. Open items / dependencies to assign owners in the meeting

| Item | Owner | Why it matters |
|---|---|---|
| Real iOS/Android bundle IDs for redirect URI | Mobile lead | Blocks External ID app registration |
| `oid` vs `sub` as the canonical user key | You + Identity team | Drives entire SQL schema |
| Operator dual-issuer handling (internal tenant) | You | Admin endpoints & `ApproverId` |
| Tours / locks / notifications table DDL | You | Not yet in v0.2 SAD |
| Gallagher lock protocol | Integration dev + Gallagher | Lock endpoint contract |
| Runtime (.NET vs Node) | You | Build start |
| Migration tooling | You | Schema delivery from day one |
| SAD sign-off + border FW CR date | PM / you | Hard gate on all of the above |

---

## Suggested 60-minute agenda

1. (5 min) Confirm Scenario B scope — no Identity API, auth at APIM.
2. (15 min) **Identity-to-data binding** — OID as user key; profile JIT provisioning; dual-issuer operators. *(the decision everything else hangs on)*
3. (15 min) SQL schema walkthrough — fix `UserId`, complete missing tables, migration approach.
4. (10 min) API contract / OpenAPI — endpoint surface, mock-token strategy for mobile.
5. (10 min) Mobile/MSAL + redirect URI + device push registration.
6. (5 min) Assign open items + owners, confirm start tasks.
