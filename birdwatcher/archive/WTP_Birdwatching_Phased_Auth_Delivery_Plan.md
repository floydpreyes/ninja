# WTP Birdwatching App — Scenario B Direct Delivery Plan

**Document Version:** 2.0  
**Date:** 2 June 2026  
**Author:** AIS Team  
**Status:** Draft for Review

---

## Context

Team consensus has settled on **Scenario B (Entra External ID)** as the sole production identity implementation. The custom SQL Auth approach — and its associated Identity API, auth table schema, JWT key management, and ongoing security obligations — will not be built.

Entra External ID is not yet provisioned within the Melbourne Water Azure tenancy. Given Melbourne Water's procurement and security governance lead times, provisioning may not be immediate. Rather than delaying the entire project, the team will adopt a **parallel stream approach**:

- **Stream A — Non-Auth Components:** Everything except authentication can be built immediately after SAD sign-off. Infrastructure, the Operations API, APIM routing and rate limiting, networking, CI/CD, Notification Hubs, Key Vault, and monitoring are all independent of External ID availability.
- **Stream B — Entra External ID:** Tenant setup and configuration is a small body of work (~4 AIS days) that slots in as soon as Melbourne Water provisions External ID. The APIM JWT validation policy is a single update that connects the deployed infrastructure to External ID once the OIDC metadata URL is known.

This means:
- **No rework.** Everything built in Stream A is final — nothing gets replaced or migrated later.
- The Operations API is completely auth-provider agnostic; auth is enforced at APIM.
- Stream B effort is minimal and can be absorbed at any point in the schedule without disrupting Stream A.
- The two-phase Scenario A → Scenario B migration cost (14 AIS days) is entirely eliminated.

> **Architecture note:** The SAD must receive formal sign-off from both the Architecture Governance and Cybersecurity teams before any infrastructure build commences. This is a hard gate on Stream A delivery.

---

## Parallel Stream Strategy

### What Can Be Built Without Entra External ID (Stream A)

| Component | External ID Dependency | Notes |
|-----------|----------------------|-------|
| Infrastructure as Code (Bicep — all environments) | None | VNet, subnets, APIM, App Service (existing EP1 plans), Azure SQL, Key Vault, NSGs, Azure Firewall |
| SQL data schema — permits, visits, sightings, hazards, tours, locks, notifications | None | Auth tables (`Users`, `RefreshTokens`, `UserProfiles`) are **not created** |
| Operations API | None | All business logic endpoints; auth enforced at APIM — Operations API is auth-provider agnostic |
| APIM routing, rate limiting, products, Named Values | None | Fully configurable now |
| APIM JWT validation policy | None *(OIDC URL only)* | Configure `validate-jwt` targeting External ID OIDC issuer. If the MW External ID tenant name is known before it is live, the metadata URL can be pre-populated |
| Entra ID — operator app registration, roles, APIM admin product | None | Internal MW Entra tenant — independent of External ID |
| Network / Border Firewall CR, Cloudflare WAF, Azure Firewall rules | None | Full public and operator network paths |
| CI/CD pipelines — all environments | None | **No Identity API pipeline** is created |
| Notification Hubs integration | None | **Shared Services subscription** — one Standard-tier namespace; two hubs (`hub-birdwatcher-dev` APNs sandbox, `hub-birdwatcher-prod` APNs production). No Dev/UAT/Prod namespace split. |
| Key Vault configuration | None | JWT signing key is **not stored** (External ID uses RS256 with Microsoft-managed keys) |
| Monitoring and alerting (App Insights, Log Analytics, alerts) | None | |
| Operations API integration testing | Partial | Can run with mock bearer tokens; replaced with real External ID tokens when Stream B is complete |

### What Requires Entra External ID (Stream B)

| Component | Dependency | Owner |
|-----------|-----------|-------|
| Entra External ID tenant provisioned | Melbourne Water tenancy approval and procurement | AIS Team to engage MW identity / platform team immediately and track |
| External ID tenant configuration — branding, MFA (Email OTP), user flows, API scope, public mobile client app registration | Tenant provisioned | AIS Team |
| APIM JWT validation policy update — replace placeholder with External ID OIDC issuer and RS256 | Tenant OIDC metadata URL confirmed | AIS Team (~1 day) |
| Mobile app MSAL integration | External ID app registration complete | Web Development team — can run in parallel with Stream A Operations API build |
| End-to-end authentication integration testing | All above | AIS + Web Dev |

---

## Stream A — Non-Auth Delivery

### Timeline — Aggressive Schedule

Sign-off target: **22 June 2026** (compressed 3-week governance cycle). The border firewall Change Request must be submitted **the same day as SAD sign-off** to meet its 2–4 week lead time before dev environment testing begins.

| Phase | Activity | Start | End | Duration |
|-------|----------|-------|-----|----------|
| **Gate 1** | SAD v0.2 submitted — Architecture Governance and Cybersecurity review | 8 Jun | 12 Jun | 1 week |
| **Gate 1** | Feedback incorporation and Q&A cycle | 15 Jun | 19 Jun | 1 week |
| **Gate 1** | Architecture / Cybersecurity formal sign-off *(milestone)* | 22 Jun | 22 Jun | — |
| **Network** | Border firewall CR submitted to MW Network Team *(same day as sign-off)* | 22 Jun | 22 Jun | — |
| **Development** | Infrastructure as Code (Bicep — Dev environment; incl. Azure Firewall, VNet, APIM, NSGs) | 23 Jun | 26 Jun | 4 days |
| **Development** | SQL data schema *(data tables only — no auth tables)* | 29 Jun | 1 Jul | 3 days |
| **Development** | Operations API (permits, visits, sightings, hazards, tours, locks, notifications) | 2 Jul | 22 Jul | 18 days |
| **Stream B** | *Entra External ID tenant configuration — runs in parallel when provisioned (see Stream B)* | *TBC* | *TBC* | *3 days (AIS)* |
| **Development** | APIM configuration (routing, JWT validation, rate limiting, Named Values) | 23 Jul | 25 Jul | 3 days |
| **Network** | Firewall and Cloudflare changes — publish APIM and Operations API *(CR target: implemented by 14 Jul; this task is final smoke test and Cloudflare config)* | 28 Jul | 30 Jul | 3 days |
| **Development** | Entra ID — operator app registration, roles, APIM admin product | 28 Jul | 29 Jul | 2 days |
| **Development** | CI/CD pipelines — all environments | 30 Jul | 31 Jul | 2 days |
| **Development** | Notification Hubs integration | 3 Aug | 4 Aug | 2 days |
| **Development** | Key Vault configuration and Monitoring / Alerting (App Insights, Log Analytics, alerts) | 5 Aug | 7 Aug | 3 days |
| **Testing** | Integration testing with mobile team (Operations API — mock tokens if External ID not yet ready; replaced with real tokens when Stream B complete) | 10 Aug | 21 Aug | 10 days |
| **UAT** | UAT and smoke tests | 24 Aug | 28 Aug | 5 days |
| **Production** | Production cutover | 31 Aug | 4 Sep | 5 days |
| **Documentation** | Documentation and handover | 7 Sep | 10 Sep | 4 days |
| **Hypercare** | Hypercare period | 7 Sep | 18 Sep | 10 days |

**Stream A production target (best case — External ID available before 10 Aug): week of 31 August 2026**

---

### Network Architecture and Firewall Change Requirements

#### Network Path

In Scenario B, there is no Identity API. The mobile app authenticates directly with Entra External ID via MSAL (out-of-band from Melbourne Water infrastructure), then presents the resulting bearer token to APIM. APIM validates the JWT against the External ID OIDC endpoint and forwards authenticated requests to the Operations API.

All public mobile API traffic traverses the following path:

```
Mobile App
   |  (1) MSAL auth flow — direct to Entra External ID (Microsoft-hosted)
   |      Returns signed bearer token (RS256, External ID issuer)
   |
   |  (2) API calls with bearer token
   ▼
Public Internet
        |
        ▼
   Cloudflare
   (WAF, DDoS mitigation, CDN, TLS edge termination)
        |
        ▼
  Border Firewall
  (MW on-premises perimeter — inbound rule: Cloudflare IP ranges → ExpressRoute)
        |
        ▼
   ExpressRoute Circuit
   (private WAN path from MW on-premises to Azure)
        |
        ▼
  Azure Firewall
  (hub VNet — DNAT / application rules: ExpressRoute GW subnet → APIM subnet)
        |
        ▼
     Azure APIM
  (Standard v2, VNet-integrated, internal mode — validates JWT against External ID OIDC, routing, rate limiting)
        |
        ▼
  Operations API
  (App Service — APIM outbound IPs only, no direct internet access)
```

The operator web app path does **not** traverse Cloudflare. Operator traffic originates on the MW corporate network and reaches APIM via the ExpressRoute → Azure Firewall path directly.

#### Required Changes Per Network Hop

| Network Hop | Component Owner | Change Required | Lead Time |
|-------------|----------------|-----------------|----------|
| **Cloudflare** | AIS Team (config) | Configure Cloudflare as reverse proxy for the dev APIM hostname. Set origin to the border firewall/ExpressRoute ingress IP. Apply WAF ruleset (OWASP Core). Lock origin so only Cloudflare IPs reach the border firewall. | 0.5 days — AIS team self-service |
| **Border Firewall** | MW Network Team | Raise Change Request: allow Cloudflare published egress IP ranges inbound on port 443 → ExpressRoute interface. Allow MW corporate subnet outbound → ExpressRoute → Azure Firewall (operator path). Deny all other direct inbound to Azure. | **2–4 week CR lead time** — must be submitted before dev build commences |
| **ExpressRoute** | MW Network Team / Azure | Confirm existing ExpressRoute circuit has capacity and correct peering (private peering to hub VNet). Provision or confirm Virtual Network Gateway in hub VNet. Advertise APIM subnet range via BGP if not already included. | 1–2 days Azure config (if circuit exists); escalate if new circuit or VLAN needed |
| **Azure Firewall** | AIS Team (IaC) | Provision Azure Firewall (or confirm shared hub instance). Create DNAT rule: ExpressRoute GW subnet → APIM private IP, port 443. Create application rule: APIM subnet → App Service backend FQDNs. Create application rule: APIM → Azure SQL private endpoint. Block all other inbound. | 1.5 days — Bicep IaC; included in Stream A IaC estimate |
| **APIM (VNet integration)** | AIS Team (IaC) | Deploy APIM Standard v2 in internal VNet mode. Configure APIM subnet with NSG: allow inbound from Azure Firewall private IP only. Configure private endpoint on Operations API Web App: allow APIM outbound subnet only. | 0.5 days — included in APIM configuration estimate |

#### Firewall Change Request — What to Include

The CR raised with the MW Network Team for the border firewall must specify:

- **Source:** [Cloudflare egress IP ranges](https://www.cloudflare.com/ips/) — both IPv4 and IPv6 lists (published and maintained by Cloudflare)
- **Destination:** ExpressRoute ingress interface / MW DMZ handoff IP
- **Port / Protocol:** TCP 443 (HTTPS)
- **Direction:** Inbound from internet via Cloudflare only
- **Justification:** Public-facing API gateway for WTP Birdwatching App; all traffic WAF-filtered by Cloudflare before reaching the perimeter
- **Dev environment scope:** Dev APIM hostname only at this stage; separate CRs will be raised for UAT and Production environments
- **Return traffic:** Stateful — permit established/related return traffic
- **Operator path addition:** Permit MW corporate LAN subnets → ExpressRoute → Azure Firewall (TCP 443, for operator web app and APIM admin product access)

> **Important:** Cloudflare IP ranges change periodically. The border firewall ruleset must reference the Cloudflare-maintained IP list and be reviewed when Cloudflare publishes updates. Cloudflare also supports an Authenticated Origin Pulls feature which should be enabled to cryptographically verify that traffic genuinely originated from Cloudflare — this supplements IP allowlisting.

#### Network Dependency on Stream A Timeline

The border firewall CR lead time of 2–4 weeks is a **critical path dependency**. Under the aggressive schedule, SAD sign-off falls on **22 June**. The CR must be submitted the same day to target implementation by 14 July and unblock end-to-end network testing during the Operations API build.

| Action | Who | When |
|--------|-----|------|
| Draft border firewall CR (detail Cloudflare IPs, ports, ExpressRoute interface) | AIS Team | 22 Jun — same day as SAD sign-off |
| Submit CR to MW Network Team | AIS Team / PM | 22 Jun |
| CR implementation by Network Team | MW Network Team | Target: 14 Jul (2-week window) |
| Azure Firewall and VNet provisioning (IaC) | AIS Team | 23–26 Jun (parallel with CR) |
| ExpressRoute gateway configuration (Azure side) | AIS Team | 23–26 Jun |
| End-to-end network path smoke test | AIS Team | 28–30 Jul — confirmed as part of Network task |

> Separate border firewall CRs must be raised for **UAT** and **Production** environments before those promotion cycles commence. Plan for the same 2–4 week lead time in each case.

---

### Stream A Effort Summary

| Work Item | Estimate (Days) | Notes |
|-----------|----------------|-------|
| Infrastructure (IaC — Bicep, Dev environment) | 4.0 | Azure Firewall policy rules, VNet, subnets, NSGs, ExpressRoute GW config, APIM, App Service private endpoints and VNet integration |
| Cloudflare configuration | 0.5 | DNS proxy, WAF ruleset (OWASP Core), Authenticated Origin Pulls, origin IP lock |
| Border firewall CR preparation | 1.0 | Document Cloudflare IP ranges, ports, operator path; prepare CR per environment |
| ExpressRoute gateway configuration (Azure side) | 1.0 | VNet Gateway provisioning or confirmation; BGP route advertisement for APIM subnet |
| SQL data schema *(data tables only — no auth tables)* | 3.0 | |
| Operations API | 18.0 | |
| APIM configuration (routing, JWT validation, rate limiting, Named Values) | 3.0 | JWT validation policy pre-configured for External ID OIDC issuer and RS256 |
| Entra ID — operator app registration, roles, APIM admin product | 2.0 | |
| CI/CD pipelines — all environments | 2.0 | No Identity API pipeline |
| Notification Hubs integration | 2.0 | Shared Services subscription. One namespace, two hubs: dev (APNs sandbox + FCM dev project) and prod (APNs production + FCM prod project — shared by UAT and Production). Operations API targets hub via app setting per environment. |
| Key Vault configuration and Monitoring / Alerting | 3.0 | JWT signing key not stored |
| End-to-end network path smoke test | 0.5 | Validate full Cloudflare → border FW → ExpressRoute → Azure FW → APIM path |
| Integration testing with mobile team | 10.0 | Mock tokens initially; replaced with External ID tokens when Stream B complete |
| Documentation and handover | 4.0 | |
| **Total — Stream A** | **54.0 days** | *~11 days fewer than Scenario A Phase 1; no Identity API, simplified SQL schema, no migration phase* |

*Assumes two DevOps/Integration Engineers working in parallel. The border firewall CR is a Network Team dependency and does not consume AIS engineer days beyond CR preparation, but its lead time (2–4 weeks) is a critical schedule constraint.*

> **Border firewall rules for Cloudflare IP ranges must be reviewed and updated whenever Cloudflare publishes changes to their egress IP list.** The MW Network Team should be notified of this ongoing maintenance requirement as part of the CR submission.

---

## Stream B — Entra External ID Setup

Stream B is independent of Stream A and can be executed at any point once Entra External ID is provisioned within the Melbourne Water tenancy. The AIS team should engage MW identity / platform teams immediately to initiate approval, running that process in parallel with Stream A development. The External ID OIDC metadata URL can be pre-populated in the APIM JWT validation policy even before the tenant is live, if the tenant name is known.

### Stream B Prerequisites

- [ ] Entra External ID provisioned and approved for use within the Melbourne Water Azure tenancy
- [ ] Identity team has confirmed tenant topology (External ID tenant separate from internal MW Entra tenant)
- [ ] Cyber Security has reviewed and accepted the External ID branding, MFA policy, and user flow configuration
- [ ] Mobile development team has capacity to update MSAL integration in the iOS and Android apps

### Stream B Effort Estimate (AIS Team)

> This covers AIS/DevOps team effort only. Mobile team MSAL integration effort is a separate estimate from the Web Development team.

| Work Item | Notes | Estimate (Days) |
|-----------|-------|----------------|
| External ID tenant configuration | Register mobile app as public client, define API scope (`Birdwatcher.Operations.ReadWrite`), apply MW branding, configure Email OTP MFA, validate user flows in dev | 3.0 |
| APIM JWT validation policy update | Update `validate-jwt` policy on all APIM products: External ID OIDC issuer, RS256, correct audience. Update Named Values (tenant metadata URL, client ID). No routing changes — `/api/auth/*` routes do not exist in this architecture. | 1.0 |
| End-to-end auth integration testing | Validate MSAL token issuance. Validate APIM JWT validation with External ID tokens. Regression test all Operations API calls with real tokens. | Included in 10-day integration testing window |
| **Total — Stream B (AIS)** | | **4.0 days** |

*Web Development team MSAL integration (iOS + Android) runs in parallel and is a separate estimate. AIS team provides the External ID app registration details and OIDC metadata URL to unblock the mobile team as early as possible.*

### Stream B Timeline — Three Scenarios

#### Best Case: External ID Available Before 10 August

Stream B completes before integration testing begins. The mobile team integrates MSAL with real External ID tokens from Day 1 of the testing phase. UAT and production proceed on the aggressive schedule.

| Milestone | Date |
|-----------|------|
| Stream A non-auth components complete | 7 Aug 2026 |
| External ID configured + APIM policy updated | Before 10 Aug |
| Integration testing — full auth with External ID tokens | 10 Aug – 21 Aug |
| UAT and smoke tests | 24 Aug – 28 Aug |
| **Production cutover** | **31 Aug – 4 Sep 2026** |
| Documentation and handover | 7 Sep – 10 Sep |
| Hypercare period | 7 Sep – 18 Sep |

#### Mid Case: External ID Available During Integration Testing (10–21 Aug)

Integration testing starts with mock bearer tokens for the Operations API. Stream B completes mid-window. A focused 2–3 day re-test validates the External ID token flow end-to-end. No schedule impact to UAT if complete before 22 August.

#### Late Case: External ID Not Available by 21 August

Integration testing completes with mock tokens — the Operations API is fully validated. Stream B is deferred until External ID is provisioned. UAT and production shift right proportionally; Stream A readiness is unaffected.

| External ID Availability | Estimated Production Cutover |
|--------------------------|------------------------------|
| Before 10 Aug (best case) | 31 Aug – 4 Sep 2026 |
| During integration testing (Aug) | Sep 2026 (minimal shift) |
| End of September | Oct 2026 |
| Q4 2026 | Nov – Dec 2026 |
| Q1 2027 | Q1–Q2 2027 |

---

## Combined Effort Summary

| Stream | AIS Effort | Key Dependency | Notes |
|--------|-----------|---------------|-------|
| Stream A — Non-Auth Components | 54 days | SAD sign-off (22 Jun) + border FW CR submitted same day | Ops API, APIM, IaC, networking, CI/CD, monitoring — all production-ready independent of auth |
| Stream B — Entra External ID | 4 days (AIS) + Web Dev MSAL effort | MW Entra External ID provisioned | Slots in at any point; 4 AIS days once provisioned |
| **Total — Scenario B Direct** | **~58 days** | | vs 79 days (65 Phase 1 + 14 Phase 2 migration) under old Scenario A approach |

**Savings vs Scenario A + Migration:**

| | Scenario A + Migration (superseded) | Scenario B Direct (this plan) |
|---|---|---|
| AIS Effort | 65 + 14 = **79 days** | **~58 days** |
| Production Date | Nov 2026 | Aug–Sep 2026 (best case) |
| Post-launch Migration Risk | Full auth layer migration in production | None — built once, no migration |
| Ongoing Security Obligations | Identity API patching, JWT key rotation, password hash review, refresh token audit, pentest on auth flows | None — delegated to Microsoft (External ID) |

---

## Risks and Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Entra External ID provisioning delayed significantly within MW tenancy | Medium | High — delays production cutover proportionally; Stream A unaffected | Engage MW identity / platform team immediately; escalate through architecture governance; track weekly. Stream A delivers full value independent of this timeline. |
| SAD not approved by 22 Jun (governance delay) | Medium | High — pushes all Stream A dates right | Submit SAD for review by 8 Jun; flag as priority in Architecture queue; schedule review meetings proactively |
| Border firewall CR delayed beyond 4 weeks | Medium | High — blocks end-to-end network testing even if Azure environment is ready | Submit CR the same day as SAD sign-off (22 Jun); pre-socialise with MW Network Team during the governance review period |
| Border firewall CR not raised in time for UAT or Production promotions | Medium | Medium — delays environment promotion | Add CR submission as a gating task 4 weeks before each environment promotion date |
| ExpressRoute circuit does not cover APIM subnet or BGP advertisement missing | Low | High — traffic will not route from on-premises to APIM | Confirm ExpressRoute peering and route table with MW Network Team before IaC build commences (during governance review period) |
| Azure Firewall is shared hub infrastructure — change requires separate approval | Medium | Medium — delays Azure Firewall rule deployment | Confirm with MW cloud team whether hub Azure Firewall is shared; if so, engage early and include in CR planning |
| Cloudflare IP range update causes border firewall to silently drop traffic | Low | Medium — public mobile app becomes unreachable | Subscribe to Cloudflare IP change notifications; establish process for MW Network Team to update FW rules on publication |
| Mobile team MSAL integration longer than estimated | Medium | Medium — may extend integration testing if External ID is available | Engage Web Dev team early; provide External ID app registration details as soon as tenant is configured |
| External ID tenant topology not confirmed (separate vs shared MW tenant) | Low | Medium — may require rework of app registrations and APIM policy | Confirm topology with MW identity team before External ID tenant configuration begins |
| Penetration testing findings require Operations API rework | Medium | Medium — extends UAT | Schedule pentest early in UAT; scope to include APIM JWT validation and Operations API endpoints |

---

## Recommendation

Proceed directly with **Scenario B (Entra External ID)** using the parallel stream approach described in this document. 

**Immediate actions:**
1. Submit SAD v0.2 for Architecture Governance and Cybersecurity review by **8 June**.
2. Engage MW identity / platform team immediately to initiate Entra External ID provisioning — this is the only hard dependency that cannot be accelerated by the AIS team.
3. Submit the border firewall Change Request on the **same day as SAD sign-off (22 June target)** to avoid blocking dev environment testing.

This approach delivers the target production architecture in a single build, avoids the 14-day Scenario A → Scenario B migration, eliminates all custom identity security obligations, and advances the production target from November 2026 to **August–September 2026** (best case). If External ID provisioning is delayed, Stream A components remain fully production-ready and the delay is isolated to the authentication layer only.
