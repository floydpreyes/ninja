# WTP Birdwatching App — Epics, Stories & Backlog (Jira Import Pack)

**Version:** 1.0
**Date:** 30 June 2026
**Author:** AIS Team
**Audience:** Delivery team, Product Owner, Scrum Master
**Purpose:** A ready-to-share backlog the team can copy into Jira. Epics map 1:1 to the
existing board (API, App Functionality, Content Management, Mapping, BACID Locks, Login,
Notifications, Admin Interface, Testing) plus two delivery epics (Identity / External ID and
Platform / DevOps) that the architecture and effort estimate require.

---

## How to use this document

- **Epics** = the top-level items already on your board. Each has an ID like `EP-01`.
- **Stories** sit under an epic and use the `US-xx` IDs. Each has a user-story statement and
  **acceptance criteria** (Given/When/Then style where useful).
- **Spikes** are time-boxed investigations (e.g. the MSAL spike already on the board).
- **Estimates** are story points (Fibonacci) as a starting point — re-estimate in refinement.
- **Labels** / **Components** are suggestions for filtering in Jira.

### Suggested Jira field mapping

| Doc field | Jira field |
|-----------|------------|
| `EP-xx` / `US-xx` title | Summary |
| User-story statement | Description |
| Acceptance criteria | Description (AC section) or checklist |
| Points | Story point estimate |
| Labels | Labels / Components |
| Epic | Epic Link |

---

## Epic summary

| Epic | Title | Goal | Board match |
|------|-------|------|-------------|
| EP-01 | Identity & Access (Entra External ID) | External users can sign up / sign in securely; admins protected | Login / Spike |
| EP-02 | Login & Authentication (App) | Mobile + operator login experience built on External ID | Login |
| EP-03 | Operations API | Business API for permits, visits, sightings, hazards, locks, notifications | API |
| EP-04 | App Functionality | Core mobile app experience and self-service | App Functionality |
| EP-05 | Mapping & Navigation | Site map, birdwatching areas, wayfinding | Mapping |
| EP-06 | Content Management | Safety, site info, tours managed by operators | Content Management |
| EP-07 | BACID / Bluetooth Locks | Electronic gate access replacing physical keys | BACID Locks |
| EP-08 | Notifications & Alerts | Push notifications for hazards, closures, evacuation | Notifications |
| EP-09 | Admin / Operator Interface | Web dashboard for operators to manage users and site | Admin Interface |
| EP-10 | Platform, DevOps & Infrastructure | IaC, networking, APIM, CI/CD, edge (Cloudflare + Front Door) | (delivery) |
| EP-11 | Testing & Quality | Integration, UAT, security and performance validation | Testing |

---

## EP-01 — Identity & Access (Entra External ID)

> **Goal:** Stand up the External ID (CIAM) tenant and configure sign-up/sign-in, MFA, branding
> and admin protections so the app delegates all credential security to Microsoft.

### SPIKE-01 — MSAL authentication investigation *(already on board)*

**As a** developer **I want** to validate the MSAL + External ID sign-up/sign-in flow on iOS and
Android **so that** we confirm the token flow before committing to the full build.
**Time-box:** 3 days · **Labels:** `spike`, `identity`, `mobile`

**Done when:**
- A spike branch demonstrates MSAL sign-up, sign-in, token acquisition and silent refresh.
- PKCE + Email OTP confirmed working against a test External ID tenant.
- Findings, risks and a recommended approach documented and shared.

### US-01.1 — Provision External ID tenant
**As an** IDAM admin **I want** an external (CIAM) tenant provisioned **so that** public users are
isolated from the MW workforce tenant. · **Points:** 5 · **Labels:** `identity`, `infra`

**Acceptance criteria:**
- Resource group `rg-hub-ase-extid` created in `0.MelbWater-Shared-Svcs`, tagged per MW standard.
- External tenant `melbwaterext.onmicrosoft.com` created; data residency = Australia (recorded as immutable).
- MAU billing model linked; Cost Management budget + alert created.
- Tenant reachable via Entra admin centre and `https://melbwaterext.ciamlogin.com`.

### US-01.2 — App registrations per environment
**As a** developer **I want** mobile, API and operator app registrations per environment **so that**
no app objects are shared across dev/UAT/prod. · **Points:** 3 · **Labels:** `identity`

**Acceptance criteria:**
- `birdwatcher-mobile-<env>` (public/native, PKCE), `birdwatcher-api-<env>` (exposes
  `Birdwatcher.Operations.ReadWrite`), `birdwatcher-operator-<env>` registered per env.
- Redirect URIs configured; no shared registrations between environments.

### US-01.3 — User flows (sign-up / sign-in / SSPR / profile edit)
**As a** public user **I want** sign-up, sign-in, password reset and profile edit flows **so that** I
can self-serve without operator involvement. · **Points:** 5 · **Labels:** `identity`

**Acceptance criteria:**
- Email + OTP enabled as baseline; sign-up collects `displayName`, `vehicleRego`, `accountApproved`.
- SSPR works end-to-end with no operator involvement.
- MW branding (logo, colours) applied at tenant level.

### US-01.4 — Admin security (MFA, PIM, Conditional Access, break-glass)
**As a** security lead **I want** privileged roles protected **so that** admin access is least-privilege
and monitored. · **Points:** 5 · **Labels:** `identity`, `security`

**Acceptance criteria:**
- MFA enforced on all admin roles; PIM eligible assignments configured.
- CA requires MFA for admin sign-ins; end users get risk-based step-up only (no device controls).
- Break-glass cloud-only accounts created, excluded from CA blocking, with sign-in alerting.

### US-01.5 — Custom URL domain via Azure Front Door
**As a** user **I want** a branded login domain (`login.melbournewater.com.au`) **so that** the sign-in
experience is trusted and on-brand. · **Points:** 3 · **Labels:** `identity`, `infra`

**Acceptance criteria:**
- Custom domain verified on the tenant (TXT) and associated as a custom URL domain.
- Front Door profile created (origin = `<tenant>.ciamlogin.com`, **WAF/caching empty** per MS guidance), managed TLS, route enabled.
- MSAL config + redirect URIs updated; full flow validated through the custom domain.

---

## EP-02 — Login & Authentication (App)

### US-02.1 — Mobile sign-up (first-time visitor)
**As a** new public user **I want** to sign up in the app **so that** I can access permit and site
features. · **Points:** 5 · **Labels:** `mobile`, `auth`

**Acceptance criteria:**
- "Sign up" launches the External ID sign-up flow (system browser / embedded).
- Email OTP verification succeeds; profile attributes captured; tokens returned to app.
- First authenticated API call to Operations API succeeds with the bearer token.

### US-02.2 — Returning user sign-in + silent token refresh
**As a** returning user **I want** to stay signed in **so that** I'm not re-prompted every session.
**Points:** 3 · **Labels:** `mobile`, `auth`

**Acceptance criteria:**
- Cached account signs in silently; MFA challenged only when risk requires it.
- Refresh token acquires access tokens silently for subsequent API calls.

### US-02.3 — Forgotten password (self-service)
**As a** user **I want** to reset my password in-app **so that** I don't need operator help.
**Points:** 2 · **Labels:** `mobile`, `auth`

**Acceptance criteria:**
- "Forgot password" launches SSPR; email-verified reset completes with no operator involvement.

### US-02.4 — Public (unauthenticated) access
**As a** member of the public **I want** to use maps and site info without logging in **so that** I can
explore before applying. · **Points:** 3 · **Labels:** `mobile`

**Acceptance criteria:**
- App launches with maps and general site info available with no login.
- Protected features clearly prompt for sign-in only when needed.

---

## EP-03 — Operations API

> **Goal:** Auth-provider-agnostic business API (auth enforced at APIM). No identity/auth tables.

### US-03.1 — UserProfiles & permit state endpoints
**As an** operator **I want** user profile and permit-state data **so that** I can see who holds access
and its validity. · **Points:** 8 · **Labels:** `api`

**Acceptance criteria:**
- CRUD for `UserProfiles` (user details, permit type long/short, permit state).
- Existing ~3K users importable (no OID); new users linkable on first sign-in.
- OpenAPI documented; APIM enforces `validate-jwt`.

### US-03.2 — Visits / site presence endpoints
**As an** operator **I want** to know who is on site **so that** I can respond to safety events.
**Points:** 5 · **Labels:** `api`

**Acceptance criteria:**
- Endpoints record site entry/exit and current presence.
- Operator query returns current on-site list.

### US-03.3 — Sightings, hazards & issue reports
**As a** birdwatcher **I want** to report sightings, hazards and injured wildlife **so that** operators
are informed. · **Points:** 5 · **Labels:** `api`

**Acceptance criteria:**
- Create/list endpoints for sightings, hazards and issue reports (with optional location/photo ref).
- Operator state transitions (e.g. acknowledged / resolved) supported.

### US-03.4 — Tours, locks & notifications data endpoints
**As a** developer **I want** endpoints for tours, locks and notifications **so that** the app and admin
features have a data source. · **Points:** 5 · **Labels:** `api`

**Acceptance criteria:**
- CRUD for tour content references, lock registry and notification records.
- Schema covers permits, visits, sightings, hazards, tours, locks, notifications — **no auth tables**.

### US-03.5 — APIM JWT validation & rate limiting
**As a** platform engineer **I want** APIM to validate External ID tokens **so that** the API trusts the
gateway only. · **Points:** 3 · **Labels:** `api`, `infra`

**Acceptance criteria:**
- `validate-jwt` targets External ID OIDC issuer (RS256), audience = `birdwatcher-api`.
- Rate limiting and Named Values configured; API does not validate tokens itself.

---

## EP-04 — App Functionality

### US-04.1 — Profile self-service (update personal details)
**As a** birdwatcher **I want** to update my details in-app **so that** my information stays current.
**Points:** 3 · **Labels:** `mobile`

**Acceptance criteria:** Profile edits persist via the profile-edit flow / Operations API; vehicle
registration editable.

### US-04.2 — Safety induction information
**As a** visitor **I want** to read safety induction info **so that** I understand site hazards before
visiting. · **Points:** 3 · **Labels:** `mobile`, `content`

**Acceptance criteria:** Induction content viewable; completion state recorded where required.

### US-04.3 — Site introduction & visit planning
**As a** visitor **I want** introductory info and trip-planning **so that** I can plan my visit.
**Points:** 3 · **Labels:** `mobile`

**Acceptance criteria:** Intro content and planning views render; deep-link to permit application
(short-term redirect / long-term in-app) works.

### US-04.4 — Report an issue (hazard / injured wildlife)
**As a** visitor **I want** to report an issue with optional photo and location **so that** operators
can act. · **Points:** 5 · **Labels:** `mobile`

**Acceptance criteria:** Issue submitted to Operations API; user sees confirmation and status.

---

## EP-05 — Mapping & Navigation

### US-05.1 — Interactive site map (public)
**As a** user **I want** an interactive WTP map **so that** I can see birdwatching areas and hazards.
**Points:** 5 · **Labels:** `mobile`, `maps`

**Acceptance criteria:** Map renders offline-tolerant base layer; birdwatching areas and gates shown.

### US-05.2 — Wayfinding / navigate to areas
**As a** visitor **I want** to navigate to birdwatching areas **so that** I can move around the large
site safely. · **Points:** 5 · **Labels:** `mobile`, `maps`

**Acceptance criteria:** Route guidance to selected area; current location displayed; hazard zones
highlighted.

### US-05.3 — Map content managed by operators
**As an** operator **I want** to update map points (areas, hazards, gates) **so that** the map stays
accurate. · **Points:** 5 · **Labels:** `maps`, `admin`

**Acceptance criteria:** Operator edits to map features reflect in the app after sync.

---

## EP-06 — Content Management

### US-06.1 — Manage safety & site content
**As an** operator **I want** to create/edit safety and site content **so that** visitors see current
information. · **Points:** 5 · **Labels:** `content`, `admin`

**Acceptance criteria:** CRUD for content items; publish/unpublish; versioning of published content.

### US-06.2 — Guided digital tour authoring
**As an** operator **I want** to author guided tours **so that** visitors get a self-guided experience.
**Points:** 5 · **Labels:** `content`, `admin`

**Acceptance criteria:** Tour steps (text, media, map points) authored and published; app renders the
tour.

### US-06.3 — Media asset management
**As an** operator **I want** to upload and manage media **so that** content includes images/audio.
**Points:** 3 · **Labels:** `content`

**Acceptance criteria:** Media uploaded to blob storage; referenced by content; size/type validated.

---

## EP-07 — BACID / Bluetooth Locks

### US-07.1 — Lock registry & assignment
**As an** operator **I want** to register Bluetooth locks and assign access **so that** approved
visitors can open relevant gates. · **Points:** 5 · **Labels:** `bacid`, `admin`

**Acceptance criteria:** Locks registered; access grants tied to permit/area; revocation supported.

### US-07.2 — Open Bluetooth gate from app
**As a** visitor **I want** to open an authorised gate from the app **so that** I don't need a physical
key. · **Points:** 8 · **Labels:** `bacid`, `mobile`

**Acceptance criteria:** App opens gate only when authorised; unlock event recorded; failure handled
gracefully when out of range / unauthorised.

### US-07.3 — Access audit & on-site visibility
**As an** operator **I want** lock/access events logged **so that** I know who entered and when.
**Points:** 3 · **Labels:** `bacid`, `admin`

**Acceptance criteria:** Unlock events feed visit/presence data; operator can review access history.

---

## EP-08 — Notifications & Alerts

### US-08.1 — Notification Hubs integration (APNs + FCM)
**As a** platform engineer **I want** Notification Hubs configured **so that** push works on iOS and
Android. · **Points:** 5 · **Labels:** `notifications`, `infra`

**Acceptance criteria:** Shared Services namespace; dev + prod hubs; device registration on sign-in.

### US-08.2 — Operator broadcast (hazard / closure / evacuation)
**As an** operator **I want** to send real-time alerts **so that** visitors are warned of hazards or
told to evacuate. · **Points:** 5 · **Labels:** `notifications`, `admin`

**Acceptance criteria:** Operator sends targeted/broadcast push; delivery status visible; evacuation
alert prioritised.

### US-08.3 — In-app notification centre & opt-in
**As a** visitor **I want** to see and manage notifications **so that** I don't miss important alerts.
**Points:** 3 · **Labels:** `notifications`, `mobile`

**Acceptance criteria:** Notification history viewable; permission prompts handled; safety alerts
cannot be silently lost.

---

## EP-09 — Admin / Operator Interface

### US-09.1 — Operator dashboard sign-in (MW tenant)
**As an** operator **I want** to sign in to the web dashboard with my MW account **so that** access is
governed by MW IDAM. · **Points:** 3 · **Labels:** `admin`, `auth`

**Acceptance criteria:** Operator app registration + app roles (`WTP.Operator`, `WTP.Admin`); HTTPS
redirect URIs; role-gated UI.

### US-09.2 — Manage users (create, update, renew, cancel)
**As an** operator **I want** to manage user accounts and permits **so that** I can onboard and maintain
access holders. · **Points:** 5 · **Labels:** `admin`

**Acceptance criteria:** Create new user → sends registration + app-download link; update/renew/cancel
permits; long/short term handled.

### US-09.3 — Site presence & safety dashboard
**As an** operator **I want** to see who is on site **so that** I can respond to incidents.
**Points:** 5 · **Labels:** `admin`

**Acceptance criteria:** Live on-site list; issue/hazard reports queue; links to broadcast alerts.

### US-09.4 — Manage access applications
**As an** operator **I want** to review and action access applications **so that** approvals are
tracked. · **Points:** 3 · **Labels:** `admin`

**Acceptance criteria:** Application list with approve/reject; status reflected to user; payment/permit
type captured.

---

## EP-10 — Platform, DevOps & Infrastructure

### US-10.1 — Infrastructure as Code (Bicep)
**As a** platform engineer **I want** parameterised IaC **so that** all environments deploy
consistently. · **Points:** 8 · **Labels:** `infra`, `iac`

**Acceptance criteria:** VNet/subnets/NSGs, Azure Firewall policy, APIM, App Service VNet integration +
private endpoints, Azure SQL — all parameterised per env.

### US-10.2 — Edge configuration (Cloudflare + Front Door)
**As a** platform engineer **I want** the two edges configured **so that** the API and auth planes are
protected appropriately. · **Points:** 3 · **Labels:** `infra`, `security`

**Acceptance criteria:** Cloudflare on API path (OWASP Core, Authenticated Origin Pulls, origin IP
lock); Front Door branded proxy on auth path (WAF/caching empty).

### US-10.3 — Network path & firewall CRs
**As a** platform engineer **I want** the border-firewall change requests prepared **so that** the
network path is approved per env. · **Points:** 5 · **Labels:** `infra`, `network`

**Acceptance criteria:** Cloudflare IP ranges/ports documented; ExpressRoute gateway confirmed; BGP
advertises APIM subnet; end-to-end smoke test passes.

### US-10.4 — CI/CD pipelines (all environments)
**As a** developer **I want** CI/CD for IaC, API, Static Web App and DB **so that** deployments are
repeatable via managed identity. · **Points:** 5 · **Labels:** `infra`, `cicd`

**Acceptance criteria:** Pipelines deploy each component to dev/UAT/prod; secrets via Key Vault /
managed identity; no Identity API pipeline.

### US-10.5 — Key Vault, monitoring & alerting
**As a** platform engineer **I want** monitoring and secrets management **so that** the platform is
observable and secure. · **Points:** 5 · **Labels:** `infra`, `observability`

**Acceptance criteria:** App Insights + Log Analytics; alerts configured; no JWT signing key stored
(Microsoft-managed RS256).

---

## EP-11 — Testing & Quality

### US-11.1 — Integration testing with mobile team
**As a** QA engineer **I want** to test full auth + API flows **so that** the app and backend integrate
correctly. · **Points:** 8 · **Labels:** `test`

**Acceptance criteria:** Mock tokens replaced with real External ID tokens; all Operations API calls
exercised; bug-fix cycle complete.

### US-11.2 — UAT & smoke tests across environments
**As a** QA engineer **I want** UAT and promotion smoke tests **so that** releases are validated end to
end. · **Points:** 5 · **Labels:** `test`

**Acceptance criteria:** Smoke tests pass across the full Cloudflare → firewall → ExpressRoute → Azure
FW → APIM → API path in each env.

### US-11.3 — Security & penetration validation
**As a** security lead **I want** security testing **so that** the solution meets MW cyber requirements.
**Points:** 5 · **Labels:** `test`, `security`

**Acceptance criteria:** OWASP-aligned checks on API; auth-flow abuse cases; findings triaged and
remediated.

### US-11.4 — Performance & resilience testing
**As a** QA engineer **I want** load and resilience tests **so that** the platform handles expected
volume. · **Points:** 3 · **Labels:** `test`, `performance`

**Acceptance criteria:** Target load sustained within SLAs; failover/availability behaviour validated.

---

## Suggested delivery order (high level)

1. **EP-01 / EP-10** — Identity tenant + platform foundation (critical path; firewall CR + tenant lead times).
2. **EP-03** — Operations API (largest single build).
3. **EP-02 / EP-04 / EP-05 / EP-06** — Mobile experience and content.
4. **EP-07 / EP-08 / EP-09** — Locks, notifications, operator interface.
5. **EP-11** — Continuous, intensifying toward UAT and cutover.

> Calendar driver: ~10–12 weeks SAD sign-off → production, gated by border-firewall CR (2–4 weeks per
> env) and External ID tenant provisioning — not by engineering capacity.
