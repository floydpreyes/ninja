# WTP Birdwatching App — Architecture Proposal

**Document Classification:** Official Sensitive  
**Date:** March 2026  
**Author:** Rennie LF  
**Sponsor:** Alistair McIntosh (Project Manager)  
**Sponsoring EA:** Gary Franks  

---

## 1. Executive Summary

The Western Treatment Plant (WTP) Birdwatching App is being redeveloped from a proof-of-concept into a production-ready solution. This proposal defines the architecture for the application, covering authentication, API delivery, edge security, and operator tooling.

The architecture uses SQL-based authentication with a split backend design:

```
Mobile App → Cloudflare (Reverse Proxy / WAF) → Azure APIM (API Gateway) → Identity API / Operations API → Azure SQL
```

The backend is separated into two APIs for clear separation of concerns:

- **Identity API** — Authentication, user profile management, JWT issuance
- **Operations API** — Business logic: permits, visits, bird sightings, hazard reporting, Bluetooth triggers, virtual guided tours, notifications

An **Operator Web App** provides WTP staff with an admin dashboard for permit management, visitor tracking, and push notification dispatch. It connects directly to APIM from the MW corporate network (bypassing Cloudflare).

**Delivery is split across two teams:**

| Team | Responsibility |
|------|---------------|
| **DevOps Team** | Identity API, Azure Notification Hubs integration, Operator Web App hosting, Azure infrastructure, APIM configuration, Cloudflare setup, Azure SQL, CI/CD pipelines, monitoring |
| **Web Development Team** | Operations API (permits, visits, birds, hazards, tours, locks, content + admin endpoints; assists with `/api/notifications` for Notification Hubs integration), iOS and Android mobile apps (auth screens, permit flows, Bluetooth, push notifications), Operator Web App UI (React/Blazor SPA — permit management, visitor tracking, push notification dispatch, Bluetooth lock admin) |

---

## 2. Architecture Overview

### 2.1 Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Edge security | Cloudflare | Reverse proxy, WAF (OWASP rules), DDoS protection, CDN, rate limiting, bot detection, TLS termination |
| API gateway | Azure API Management (Standard v2) | JWT validation, per-user rate limiting, API versioning, request schema validation, path-based routing, observability |
| Identity API | Azure App Service (.NET 8+ or Node.js) | Authentication — login, registration, password reset, JWT issuance, user profile management |
| Operations API | Azure App Service (.NET 8+ or Node.js) | Business logic — permits, visits, bird sightings, hazard reporting, Bluetooth triggers, virtual guided tours, notifications, site content |
| Operator Web App | Azure Static Web App or App Service | Admin dashboard for WTP operators — permit approval, visitor tracking, push notifications, Bluetooth lock management. Authenticates via Entra ID (internal MW tenant) |
| Database | Azure SQL Database | Application data — users, credentials, permits, visits, sightings, user profiles, site content |
| Monitoring | Application Insights + Log Analytics | API telemetry, backend diagnostics, SQL auditing |
| Bluetooth | Gallagher integration | Gate lock control via Bluetooth beacons |
| Notifications | Azure Notification Hubs | Push alerts from WTP operators to mobile app users |

### 2.2 APIM Path-Based Routing

APIM routes requests to the appropriate backend API based on URL path prefix:

| Path Prefix | Target |
|-------------|--------|
| `/api/auth/*` | Identity API |
| `/api/profile/*` | Identity API |
| `/api/permits/*` | Operations API |
| `/api/visits/*` | Operations API |
| `/api/birds/*` | Operations API |
| `/api/hazards/*` | Operations API |
| `/api/tours/*` | Operations API |
| `/api/locks/*` | Operations API |
| `/api/notifications/*` | Operations API |
| `/api/content/*` | Operations API |

### 2.3 Network Security

**Public traffic (mobile app):**
```
Internet → Cloudflare (edge IPs) → APIM (accepts only Cloudflare IPs) → Identity API / Operations API (accept only APIM via VNet) → Azure SQL (private endpoint only)
```

**Internal traffic (operator web app):**
```
MW Corporate Network → APIM (direct, no Cloudflare) → Identity API / Operations API (via VNet) → Azure SQL (private endpoint only)
```

- Cloudflare terminates public TLS; origin certificate secures Cloudflare → APIM
- APIM public API product restricts source IPs to Cloudflare ranges
- APIM internal/admin API product accepts requests from MW corporate network (VNet/ExpressRoute or IP-restricted)
- Operator Web App authenticates MW staff via Entra ID (internal tenant) — APIM validates Entra ID JWTs with admin role claims
- Both Identity API and Operations API App Services restrict access to APIM only (VNet integration or IP restriction)
- Azure SQL has no public endpoint — accessible only via private endpoint from the backend subnet
- TDE (Transparent Data Encryption) enabled on Azure SQL

---

## 3. Authentication Options for External Users

The architecture must authenticate two distinct populations:

- **External users** — members of the public applying for and using birdwatching permits via the mobile app.
- **Internal users** — Melbourne Water staff using the Operator Web App. These are authenticated against the **internal MW Entra ID tenant** in all options below, and are not in scope for this comparison.

This section evaluates three options for the **external** user population.

### 3.1 Options at a glance

| # | Option | Identity Store | MFA | SSPR | Social IdPs | Password Liability | Identity API Required | MW Tenancy Status |
|---|--------|---------------|-----|------|-------------|--------------------|-----------------------|-------------------|
| **A** | **SQL custom auth** (current baseline) | Azure SQL `Users` table | Build from scratch | Build from scratch | No | High — bcrypt/Argon2id hashes stored by MW | Yes — full custody | Available now |
| **B** | **Microsoft Entra External ID** *(recommended)* | Microsoft-managed external tenant | Built-in (toggle) | Built-in | Google / Apple / Microsoft / Facebook | None — MW never sees credentials | Optional — thin profile/claims service only | **Pending tenancy enablement within MW** |
| **C** | **Azure AD B2C** (legacy fallback) | Microsoft-managed B2C tenant | Built-in (user flows) | Built-in | Same as B | None | Optional | Available, but Microsoft has signalled customers should adopt External ID for new builds |

### 3.2 Decision criteria

| Criterion | Option A — SQL | Option B — External ID | Option C — B2C |
|-----------|---------------|------------------------|----------------|
| Time to deliver MFA | Months (custom build) | Hours (toggle) | Hours (user flow) |
| Self-service password reset | Custom build + email service | Built-in | Built-in |
| Social / passwordless sign-in | Not in scope | Out of the box | Out of the box |
| Compliance inheritance (SOC2 / ISO 27001 / IRAP) | MW must evidence | Inherited from Microsoft | Inherited from Microsoft |
| Breach blast-radius (password DB) | High | Nil | Nil |
| Ongoing auth code maintenance | High (forever) | Minimal (config + branding) | Minimal |
| Cost (auth tier) | App Service (~$50–80) + SendGrid (~$15) | First 50,000 MAU free; ~$0.00325 / MAU thereafter | First 50,000 MAU free; similar pricing |
| Migration friction *from* current POC | Low (extends current) | Medium (mobile MSAL + APIM re-config) | Medium (similar to B) |
| Strategic alignment | Low — diverges from MW Entra direction | High | Medium — Microsoft direction is External ID |
| Custom branding / domain | Full control, but DIY | Custom domains, branded sign-up pages, language packs | Same as B |

### 3.3 Option A — SQL custom auth (baseline)

The current proposal §5 (Identity API) describes this option in detail. It is fully buildable today using only services already approved within MW. The trade-off is that **every** common identity feature — MFA, SSPR, social login, passwordless, account lockout tuning, breach detection, anomalous-login alerting — must be designed, built, tested, and maintained by MW indefinitely. Credentials become an MW-owned liability.

### 3.4 Option B — Microsoft Entra External ID *(recommended)*

A Microsoft-managed customer identity service (CIAM) purpose-built for consumer-facing apps. Sign-up, sign-in, MFA, SSPR, branded UX, social IdPs, and audit logging are configured rather than coded.

**How it changes the architecture:**

- **Mobile app** uses **MSAL** (`MSAL.iOS` / `MSAL.Android`) to start an **OIDC Authorization Code + PKCE** flow against the External ID tenant. MSAL caches tokens in iOS Keychain / Android EncryptedSharedPreferences and handles silent refresh.
- **APIM `validate-jwt`** points at the External ID tenant's OIDC discovery document; no MW-managed signing key.
- The **Identity API shrinks** to a small profile/claims service (or is removed entirely if profile attributes can live as External ID extension attributes). The Operations API becomes the only backend.
- **User store** moves out of Azure SQL. The `Users` and `RefreshTokens` tables are no longer required; `UserProfiles` (or its replacement) keys off the External ID `oid` (object id) claim.
- **Operator-driven account approval** (if required) is implemented via a **custom policy** that blocks token issuance until an `accountApproved=true` extension attribute is set via Microsoft Graph from the Operator Web App. See §4.1.

**Pros:** No password storage; MFA/SSPR/social are toggles; inherits Microsoft's compliance posture; aligns with MW's strategic Entra direction; ~free at expected MAU.

**Cons:** Depends on External ID being enabled within the MW Azure tenancy (not yet confirmed); custom policy XML has a learning curve if branded flows or claims augmentation are needed; mobile team must adopt MSAL; APIM JWT validation and token-shape contracts change.

### 3.5 Option C — Azure AD B2C (fallback)

Functionally similar to External ID and proven in production for many years. Should be considered **only if External ID is not enablement-ready** by Phase 2. Microsoft has publicly positioned External ID as the strategic successor for new customer-facing builds, so adopting B2C now would create a known future migration.

### 3.6 Recommendation

| Scenario | Recommendation |
|----------|---------------|
| External ID is enablement-ready within MW by start of Phase 2 | **Adopt Option B from day one.** Skip the Identity API build; deliver the Operations API + Operator Web App + mobile MSAL integration. |
| External ID enablement is delayed | **Deliver Option A** as the Phase 1 release with a documented cut-over plan to Option B as a follow-on release. The split-backend architecture in this proposal already isolates auth behind the Identity API, which makes the cut-over a like-for-like swap of one component. |
| Option B is not viable for non-technical reasons | **Choose Option C (B2C)** in preference to Option A; the operational savings outweigh the eventual migration to External ID. |

The remainder of this document continues to describe Option A in detail (since it is the buildable-today baseline), with Option B-specific notes called out where the architecture or delivery scope diverges.

---

## 4. Authentication, User Creation & Approval Flows

This section describes how a user becomes a permitted birdwatcher under each option, and how operators approve permits (and optionally accounts) end-to-end. Diagrams for these flows are maintained in [WTP_Birdwatching_Auth_Scenarios.drawio](WTP_Birdwatching_Auth_Scenarios.drawio).

### 4.1 User account creation & verification

**Option A — SQL custom auth:**

1. User enters email + password on the mobile app's registration screen.
2. Mobile app calls `POST /api/auth/register` (Identity API, via Cloudflare → APIM).
3. Identity API hashes the password (Argon2id + per-user salt), inserts a `Users` row with `IsActive = 0`, generates a one-time **email verification token**, and writes it to `EmailVerifications`.
4. SendGrid / Azure Communication Services sends a verification email with a deep link.
5. User opens the deep link → mobile app calls `POST /api/auth/verify-email` → Identity API marks `IsActive = 1`.
6. *(Optional gating, off by default)* If the business requires operator approval **before first login**, step 5 instead writes an `AccountApprovals` row with `Status = Pending`. The user remains unable to log in until an operator approves the row from the Operator Web App, at which point `Users.IsActive = 1`.

**Option B — Entra External ID:**

1. User taps "Create account" in the mobile app → MSAL launches the External ID **sign-up user flow** in a system browser tab (ASWebAuthenticationSession on iOS, Custom Tabs on Android).
2. External ID collects email, password, and any required custom attributes (display name, vehicle rego), sends an **email OTP**, and verifies on submission. Optional social IdPs (Google / Apple / Microsoft) can replace the email-and-password path entirely.
3. External ID issues an ID token + access token directly to the mobile app via the OIDC redirect; MSAL caches them.
4. *(Optional gating, off by default)* If account approval is required, a **custom policy** denies token issuance when the extension attribute `extension_<appId>_accountApproved` is absent or false. The operator approves via the Operator Web App, which calls **Microsoft Graph** (`PATCH /users/{id}`) to set the attribute. The user retries sign-in and proceeds.

> **Recommendation:** leave the optional account-approval gate **off** for Option B and rely on email OTP (Option B) or email verification (Option A) plus the per-permit approval workflow in §4.3 as the gate for Bluetooth-lock entitlement. This minimises sign-up friction.

### 4.2 Login & token issuance

**Option A — SQL custom auth:**

1. Mobile app `POST /api/auth/login` → APIM (no JWT yet, public endpoint) → Identity API.
2. Identity API verifies the password against `Users.PasswordHash`, increments `FailedAttempts` on miss (locks at N), issues a **self-signed JWT access token** (signed with a Key Vault–stored key) and a refresh token.
3. Subsequent `/api/*` calls carry `Authorization: Bearer {JWT}`. APIM `validate-jwt` policy verifies the signature against the Key Vault key.
4. Mobile app silently refreshes via `POST /api/auth/refresh-token` before access-token expiry.

**Option B — Entra External ID:**

1. Mobile app calls **MSAL `acquireToken`**, which launches the External ID **sign-in user flow** (or returns a cached token).
2. External ID authenticates, applies MFA if configured, and returns ID + access tokens directly to the mobile app.
3. Subsequent `/api/*` calls carry `Authorization: Bearer {External ID JWT}`. APIM `validate-jwt` policy verifies against the External ID **OIDC discovery document** (`openid-config` URL — see §11.3) and required claims (`aud`, `tid`, `scp`).
4. MSAL refreshes silently using the refresh token; MW writes no token-refresh code.

### 4.3 Permit application & operator approval workflow

The same workflow applies under both options; the only difference is which JWT type APIM validates on the inbound calls.

**Permit state machine:**

```
   Draft ──submit──▶ Submitted ──pickup──▶ UnderReview ──┬─▶ Approved ──pay──▶ Active ──ttl──▶ Expired
                                                          ├─▶ Rejected
                                                          └─▶ InfoRequested ──resubmit──▶ Submitted
```

**End-to-end steps:**

| # | Actor | Action | API / Surface | Result |
|---|-------|--------|---------------|--------|
| 1 | Applicant (mobile) | Completes permit form, submits | `POST /api/permits` (Operations API) | `Permits.Status = Submitted`, audit row written to `PermitApprovals` (Action=`Submitted`) |
| 2 | Operations API | Routes to operator review queue | (internal) | Visible in Operator Web App dashboard |
| 3 | Operator (web app) | Picks up review, validates orientation/safety prerequisites | `PUT /api/permits/{id}/state` with `UnderReview` | `Status = UnderReview`, `PermitApprovals` row (Action=`PickedUp`, ApproverId=oid) |
| 4 | Operator | Approves / Rejects / Requests info | `PUT /api/permits/{id}/state` with body `{state, reason}` | State transitions; audit row recorded with `Reason` and `Timestamp` |
| 5 | Operations API | Dispatches push notification | Notification Hubs (tag = `userId:{n}`) | Applicant receives push: "Permit approved" / "Action required" |
| 6 | Applicant | Pays permit fee (if approved) | `POST /api/permits/{id}/payment` | `Status = Active`, `ValidFrom`/`ValidTo` set |
| 7 | Applicant | Arrives at gate, opens Bluetooth lock | `POST /api/locks/{id}/unlock` | Operations API authorises **only if** the caller has at least one `Status=Active` permit covering today; calls Gallagher SDK |
| 8 | Background job | Daily expiry sweep | (cron) | `Status = Expired` once `ValidTo < today`; lock entitlement revoked |

**Authorisation gates enforced by the Operations API:**

- `/api/permits/{id}/state` writes — caller JWT must contain role/claim `WTP.Operator` (Entra ID, internal tenant).
- `/api/locks/*` — caller must be the permit owner **and** have an `Active` permit; operators with `WTP.Operator` may also trigger locks for support/admin scenarios (audited).
- All state transitions write to `PermitApprovals` with `ApproverId`, `FromState`, `ToState`, `Action`, `Reason`, `Timestamp`. This is the system of record for IRAP-style auditability.

**Notifications:**

- Push messages are dispatched on every state transition that affects the applicant (`Approved`, `Rejected`, `InfoRequested`, `Expired`). Targeting uses Notification Hubs **tags** keyed by user id — registered by the mobile app at sign-in.
- Email fallback is sent if the device has not registered a push handle within 24 hours of a status change.

**SLA timers:**

- `Submitted → UnderReview` — operational target ≤ 2 business days. The Operator Web App highlights overdue items.
- `UnderReview → Approved | Rejected | InfoRequested` — target ≤ 5 business days end-to-end.

### 4.4 Roles & RBAC summary

| Role | Issued By | Stored In | Used By | Enforced At |
|------|-----------|-----------|---------|-------------|
| `WTP.User` (implicit) | Identity API (Option A) **or** External ID (Option B) | JWT `sub` / `oid` | Mobile app | APIM `validate-jwt`; Operations API row-level checks (`UserId == sub`) |
| `WTP.Operator` | MW internal Entra ID | App role on the Operator Web App app registration; included in JWT `roles` claim | Operator Web App | APIM admin product `validate-jwt` `required-claims`; Operations API admin endpoint guards |
| `WTP.Admin` | MW internal Entra ID | App role on the Operator Web App app registration | Operator Web App (settings, user/lock mgmt) | APIM admin product `validate-jwt`; Operations API admin endpoint guards |

**Tables added to support approval workflow:**

```sql
CREATE TABLE PermitApprovals (
    Id              INT IDENTITY PRIMARY KEY,
    PermitId        INT NOT NULL REFERENCES Permits(Id),
    ApproverId      NVARCHAR(64) NULL,           -- Entra ID oid of operator (null for system actions)
    Action          NVARCHAR(32) NOT NULL,       -- Submitted, PickedUp, Approved, Rejected, InfoRequested, Expired
    FromState       NVARCHAR(20),
    ToState         NVARCHAR(20),
    Reason          NVARCHAR(1000) NULL,
    Timestamp       DATETIME2 DEFAULT GETUTCDATE()
);

-- Option A only — operator-gated account activation (off by default)
CREATE TABLE AccountApprovals (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT NOT NULL REFERENCES Users(Id) UNIQUE,
    Status          NVARCHAR(20) NOT NULL,       -- Pending, Approved, Rejected
    ApproverId      INT NULL,
    DecidedAt       DATETIME2 NULL,
    Reason          NVARCHAR(1000) NULL
);
```

---

## 5. Authentication & User Management (Identity API)

> **Applies to Option A only.** Under Option B (Entra External ID), the Identity API is reduced to a thin profile/claims service or removed entirely; see §3.4. The detail below describes the SQL-based baseline.

### 5.1 How It Works

The mobile app collects email and password via a custom login screen. Credentials are sent through the full request chain to the Identity API, which validates them against a Users table in Azure SQL and issues a self-signed JWT.

```
Mobile App              Cloudflare            APIM                 Identity API          Azure SQL
    │                       │                    │                       │                    │
    │── POST /auth/login ──▶│───────────────────▶│── route /api/auth/* ─▶│                    │
    │   {email, password}   │   WAF filtered     │   Rate limited        │── Query Users ────▶│
    │                       │                    │                       │   table             │
    │                       │                    │                       │◀── Hash match ─────│
    │◀──────────────── JWT (self-signed) ────────│◀──────────────────────│                    │
    │                       │                    │                       │                    │
    │── GET /api/profile ──▶│───────────────────▶│── route /profile ────▶│── Query ──────────▶│
    │   Authorization: JWT  │                    │   validate-jwt        │   UserProfiles      │
    │◀──────────────── profile data ─────────────│◀──────────────────────│◀── results ───────│
```

### 5.2 Identity API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/auth/login` | POST | Validate credentials, return JWT access token + refresh token |
| `/api/auth/register` | POST | Create new user account (email, password → Argon2id hash) |
| `/api/auth/forgot-password` | POST | Generate password reset token, send reset email |
| `/api/auth/refresh-token` | POST | Exchange valid refresh token for new access token |
| `/api/profile` | GET | Retrieve current user's profile (from JWT `sub` claim) |
| `/api/profile` | PUT | Update user profile (vehicle rego, preferred area, display name) |

### 5.3 Database Schema (Identity)

```sql
-- AUTH TABLES (custom, managed by Identity API)
CREATE TABLE Users (
    Id              INT IDENTITY PRIMARY KEY,
    Email           NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(512) NOT NULL,     -- Argon2id or bcrypt
    Salt            NVARCHAR(256) NOT NULL,
    FailedAttempts  INT DEFAULT 0,
    LockedUntil     DATETIME2 NULL,
    IsActive        BIT DEFAULT 1,
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE(),
    LastLoginAt     DATETIME2 NULL
);

CREATE TABLE RefreshTokens (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT REFERENCES Users(Id),
    Token           NVARCHAR(512) NOT NULL,
    ExpiresAt       DATETIME2 NOT NULL,
    RevokedAt       DATETIME2 NULL
);

CREATE TABLE UserProfiles (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT REFERENCES Users(Id) UNIQUE,
    DisplayName     NVARCHAR(256),
    VehicleRego     NVARCHAR(20),
    PreferredArea   NVARCHAR(100),
    CreatedAt       DATETIME2 DEFAULT GETUTCDATE()
);
```

---

## 6. Operations & Business Logic (Operations API)

### 6.1 How It Works

All non-authentication API calls flow through APIM to the Operations API. APIM validates the JWT (issued by the Identity API) before forwarding the request. The Operations API handles permits, visits, bird sightings, hazard reporting, virtual guided tours, Bluetooth lock triggers, site content, and push notifications.

```
Mobile App              Cloudflare            APIM                 Operations API        Azure SQL
    │                       │                    │                       │                    │
    │── GET /api/permits ──▶│───────────────────▶│── validate-jwt ──────▶│── Query data ─────▶│
    │   Authorization: JWT  │   WAF filtered     │   route /api/permits  │                    │
    │◀──────────────── permit data ──────────────│◀──────────────────────│◀── results ───────│
    │                       │                    │                       │                    │
    │── POST /api/birds ───▶│───────────────────▶│── validate-jwt ──────▶│── Insert ─────────▶│
    │   {species, location} │                    │   route /api/birds    │   sighting          │
    │◀──────────────── 201 Created ──────────────│◀──────────────────────│◀── OK ────────────│
```

### 6.2 Operations API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/api/permits/*` | Permit application, status, renewal, payment reference |
| `/api/visits/*` | Visit check-in/check-out, visit history |
| `/api/birds/*` | Bird sighting submission, species lists, sighting history |
| `/api/hazards/*` | Hazard reporting, hazard status tracking |
| `/api/tours/*` | Virtual guided tour content, tour progress tracking |
| `/api/locks/*` | Bluetooth gate lock control (trigger via Gallagher SDK) |
| `/api/notifications/*` | Push notification registration, notification preferences |
| `/api/content/*` | Site maps, orientation content, bird species reference data |

### 6.3 Database Schema (Operations)

```sql
-- APP DATA TABLES (FK to Users in Identity schema)
CREATE TABLE Permits (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT NOT NULL,           -- References Users(Id)
    PermitType      NVARCHAR(50),
    Status          NVARCHAR(20),           -- Applied, Approved, Expired
    ValidFrom       DATE,
    ValidTo         DATE,
    PaymentRef      NVARCHAR(100)
);

CREATE TABLE Visits (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT NOT NULL,
    PermitId        INT REFERENCES Permits(Id),
    CheckInAt       DATETIME2,
    CheckOutAt      DATETIME2 NULL,
    Area            NVARCHAR(100)
);

CREATE TABLE BirdSightings (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT NOT NULL,
    VisitId         INT REFERENCES Visits(Id),
    Species         NVARCHAR(200),
    Location        NVARCHAR(200),
    SightedAt       DATETIME2 DEFAULT GETUTCDATE(),
    Notes           NVARCHAR(1000) NULL
);

CREATE TABLE Hazards (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT NOT NULL,
    Description     NVARCHAR(1000),
    Location        NVARCHAR(200),
    ReportedAt      DATETIME2 DEFAULT GETUTCDATE(),
    Status          NVARCHAR(20)            -- Reported, Acknowledged, Resolved
);
```

> **Note:** Both APIs connect to the same Azure SQL database. The Identity API manages auth tables (`Users`, `RefreshTokens`, `UserProfiles`); the Operations API manages data tables (`Permits`, `Visits`, `BirdSightings`, `Hazards`, etc.). Cross-references use `UserId` from the `Users` table.

---

## 7. Delivery Scope

### 7.1 DevOps Team

#### Identity API *(Option A only — omit if Option B is chosen)*

| Item | Detail |
|------|--------|
| **Auth endpoints** | Build `POST /api/auth/login`, `POST /api/auth/register`, `POST /api/auth/verify-email`, `POST /api/auth/forgot-password`, `POST /api/auth/refresh-token` |
| **Profile endpoints** | Build `GET /api/profile`, `PUT /api/profile` |
| **Password hashing** | Implement Argon2id or bcrypt hashing + salt generation |
| **Account lockout** | Implement lockout after N failed attempts, timed unlock |
| **JWT issuance** | Generate and sign access tokens + refresh tokens; manage signing key rotation |
| **Password reset** | Build reset flow — generate reset token, send email (via SendGrid / Azure Communication Services), validate and update |
| **Email verification** | One-time verification token issued at registration; `Users.IsActive` flipped on confirmation |

#### Entra External ID configuration *(Option B only — replaces the Identity API block above)*

| Item | Detail |
|------|--------|
| **Tenant enablement** | Coordinate with MW Identity team to enable / provision an External ID tenant |
| **App registration** | Register the mobile app (public client, PKCE) and the Operations API (resource server with scopes) |
| **User flows / custom policies** | Configure sign-up, sign-in, password-reset, profile-edit flows; add MFA (email OTP and/or authenticator); enable social IdPs as agreed (Apple required for iOS App Store, Google optional) |
| **Custom attributes** | Define extension attributes (e.g. `vehicleRego`, `displayName`, `accountApproved`) for inclusion in tokens |
| **Branding** | Apply MW branding, logo, colours, language packs to the hosted sign-up/sign-in pages |
| **Custom domain** | Configure `auth.birdwatching.melbournewater.com.au` (or similar) on the External ID tenant |
| **Microsoft Graph integration** | Grant Operator Web App backend a Graph app role to set `accountApproved` extension attribute (only if account-approval gating is enabled) |
| **Audit/log export** | Stream External ID audit logs to Log Analytics |

#### Azure Notification Hubs Integration

| Item | Detail |
|------|--------|
| **Notification Hubs provisioning** | Create Notification Hub namespace + hub, configure APNs certificate/token and FCM server key |
| **Notification Hubs SDK integration** | Implement server-side send logic in the Operations API `/api/notifications` endpoints (Web Development Team assists with endpoint integration) |
| **Push infrastructure** | Connection strings, Managed Identity access, tag-based targeting configuration |

#### Infrastructure & Platform

| Item | Detail |
|------|--------|
| **APIM JWT policy** | Configure `validate-jwt` with custom signing key (must be securely stored in Key Vault and rotated) |
| **APIM path routing** | Configure path-based routing: `/api/auth/*` and `/api/profile/*` → Identity API; all other `/api/*` → Operations API |
| **APIM products** | Public product (Cloudflare IP-restricted, custom JWT) + Admin product (MW corporate network, Entra ID JWT with admin role) |
| **Azure SQL** | Provision database, deploy schema (auth tables + app data tables), configure firewall, TDE, auditing |
| **Cloudflare** | DNS configuration, WAF rules, rate limiting (stricter on `/api/auth/*`), origin cert, SSL Full (Strict) |
| **Operator Web App hosting** | Deploy Static Web App or App Service for the admin dashboard (React/Blazor SPA) |
| **Operator Web App auth** | Configure Entra ID app registration (internal MW tenant) for operator login; APIM validates Entra ID JWT with admin role |
| **Infrastructure as Code** | Bicep/Terraform for App Services (x2), Static Web App, SQL, APIM, Key Vault, VNet, private endpoints |
| **CI/CD** | Azure DevOps / GitHub Actions pipelines for Identity API, Operations API, and Operator Web App deployment |
| **Monitoring** | App Insights dashboards, alerts for failed auth spikes, APIM 4xx/5xx rates, SQL threat detection |

### 7.2 Web Development Team

#### Operations API

| Item | Detail |
|------|--------|
| **Business endpoints** | Build endpoints for permits, visits, bird sightings, hazards, tours, locks, site content |
| **Admin endpoints** | Permit approval/rejection, visitor tracking queries, push notification dispatch, Bluetooth lock management (for operator web app) |
| **Notifications endpoints** | Build `/api/notifications/*` endpoints (registration, preferences, dispatch); integrate with Azure Notification Hubs SDK (DevOps Team provides Notification Hubs configuration and assists with SDK integration) |
| **Database operations** | CRUD operations against Operations data tables (Permits, Visits, BirdSightings, Hazards) |

#### Mobile App (iOS + Android)

| Item | Detail |
|------|--------|
| **Custom login screen** | Build native email/password login form (iOS + Android) |
| **Custom registration screen** | Build native sign-up form with validation |
| **Custom forgot-password screen** | Build password reset request UI |
| **Token storage** | Securely store JWT in iOS Keychain / Android EncryptedSharedPreferences |
| **Token refresh** | Implement silent token refresh using refresh token before access token expires |
| **API integration** | All business API calls with `Authorization: Bearer {JWT}` header |
| **Bluetooth integration** | Gallagher SDK for gate lock control |
| **Push notifications** | Register for push via Azure Notification Hubs |
| **Offline caching** | Cache bird lists, site maps, orientation content locally |
| **Certificate pinning** | Optional — pin Cloudflare origin cert with backup pins |

#### Operator Web App (React/Blazor SPA)

| Item | Detail |
|------|--------|
| **Dashboard** | Permit management, visitor tracking, hazard review |
| **Push notifications** | Interface for dispatching push alerts to mobile app users |
| **Bluetooth lock admin** | Gate lock management interface |
| **Authentication** | Entra ID (internal MW tenant) login via MSAL.js |
| **API integration** | All admin API calls with `Authorization: Bearer {Entra ID JWT}` header |

---

## 8. Risks & Mitigations

### 8.1 Risks common to both options

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Custom business-logic bugs (state-machine flaws, authorisation bypass, token leaks) | High | Medium | Security review, penetration testing, automated tests on the permit state machine |
| Cross-API data consistency | Medium | Low | Shared Azure SQL database with database-level referential integrity |
| Push notification deliverability (APNs/FCM outages) | Medium | Low | Email fallback after 24h non-delivery; retry/backoff in Operations API |
| Operator approval SLA breaches | Medium | Medium | SLA timers in Operator Web App; alerting on overdue queue depth |

### 8.2 Option A (SQL custom auth) risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Password breach — credentials stored in SQL | High | Medium | Argon2id hashing, but credentials remain a liability |
| No built-in MFA | High | Medium | Must build MFA from scratch or accept the gap; cut over to Option B as soon as External ID is enabled |
| Password reset email spoofing | Medium | Low | SPF/DKIM/DMARC on sending domain |
| Signing key compromise | High | Low | Key Vault storage, automated rotation |
| Ongoing maintenance burden for auth code | Medium | High | Every auth feature (MFA, social, SSPR) must be built and maintained; budget for cut-over to Option B |
| Identity API single point of failure | Medium | Low | App Service auto-scaling + health checks; deployment slots for zero-downtime updates |

### 8.3 Option B (Entra External ID) risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| External ID tenancy enablement delay within MW | High | Medium | Treat tenancy enablement as a Phase 0 gate; fall back to Option A with a documented cut-over plan if enablement slips beyond Phase 2 |
| Custom-policy XML complexity (if branded flows / claims augmentation needed) | Medium | Medium | Start with built-in user flows; only escalate to custom policies where business-critical |
| Social IdP outage (Apple/Google) | Low | Low | Email-OTP path remains available as primary; social IdPs are additive |
| Microsoft Graph dependency for account-approval gate | Low | Low | Account-approval gate is **off by default** (§4.1); rely on permit-approval workflow as the entitlement gate |
| Mobile MSAL upgrade cadence | Low | Medium | Pin MSAL versions; track Microsoft advisories |

---

## 9. Cost Estimate

### 9.1 Option A — SQL custom auth (baseline)

| Component | Estimated Cost (AU$/month) |
|-----------|---------------------------|
| Azure APIM (Standard v2) | ~$400 |
| Azure App Service — Identity API (B1) | ~$50–80 |
| Azure App Service — Operations API (B1/S1) | ~$80–150 |
| Azure Static Web App — Operator Dashboard (Free/Standard) | ~$0–15 |
| Azure SQL (Basic/S0) | ~$20–75 |
| Cloudflare (Pro) | ~$30 |
| SendGrid / email service (password reset, verification) | ~$15 |
| Key Vault (signing key storage) | ~$5 |
| Application Insights | ~$0–30 (consumption-based) |
| **Estimated monthly total** | **~$600–800** |

> **Note:** Developer effort to build and maintain custom auth is a significant cost not captured here. Every new auth feature (MFA, social, SSPR, breach detection) is an ongoing build.

### 9.2 Option B — Entra External ID (recommended)

Differences vs Option A:

| Component | Cost change |
|-----------|-------------|
| Identity API App Service | **Removed** (saves ~$50–80/month) |
| SendGrid / email service | **Removed** — External ID handles verification & SSPR (saves ~$15/month) |
| Key Vault JWT signing key | **Removed** (saves ~$5/month) |
| Entra External ID | **Added** — first 50,000 MAU **free**; ~$0.00325/MAU thereafter (negligible at expected volume) |
| Microsoft Graph (account-approval gate) | $0 (within standard quotas) |
| **Estimated monthly total (Option B)** | **~$530–700** |

> Beyond the line-item savings, Option B eliminates the auth-code maintenance burden entirely — typically the largest hidden cost in Option A.

---

## 10. Delivery Phases

### Phase 0 — Auth Option Decision Gate (All Teams)
- Confirm whether Microsoft Entra External ID can be enabled within the MW Azure tenancy in time for Phase 2.
- If **yes**: adopt **Option B**; skip Phase 2a (Identity API) and execute Phase 2c (External ID configuration) instead.
- If **no**: adopt **Option A** with a documented Option B cut-over backlog item.

### Phase 1 — Infrastructure & Edge Security (DevOps Team)
- Provision Azure SQL, App Services (Operations API; Identity API only under Option A), Static Web App (operator dashboard), APIM, Key Vault, VNet, private endpoints
- Configure Cloudflare DNS, WAF, rate limiting, origin certificate
- Configure APIM: path-based routing rules, public product (Cloudflare IP-restricted) + admin product (MW corporate network)
- Configure Entra ID app registration (internal MW tenant) for operator web app
- Deploy infrastructure via Bicep/Terraform
- Set up CI/CD pipelines (Operations API, Operator Web App; Identity API only under Option A)

### Phase 2a — Identity API *(Option A only — DevOps Team)*
- Build auth endpoints: login, register, verify-email, forgot-password, refresh-token
- Build profile endpoints: get profile, update profile
- Implement Argon2id password hashing, account lockout, JWT issuance
- Implement password reset email flow (SendGrid / Azure Communication Services)
- Configure APIM `validate-jwt` policy with custom signing key from Key Vault
- Deploy Identity API schema (Users, RefreshTokens, UserProfiles, EmailVerifications, optional AccountApprovals)

### Phase 2c — Entra External ID Configuration *(Option B only — DevOps Team, replaces Phase 2a)*
- Stand up the External ID tenant (or reuse the MW-provisioned tenant); register mobile app and Operations API
- Configure sign-up, sign-in, password-reset, profile-edit user flows; enable MFA
- Configure social IdPs (Apple required for iOS publishing; Google optional)
- Define custom extension attributes (`vehicleRego`, `displayName`, `accountApproved`)
- Apply MW branding and configure custom auth domain
- Configure APIM `validate-jwt` policy against the External ID OIDC discovery endpoint (see §11.3)
- Wire Microsoft Graph access from the Operations API/Operator Web App backend (only if account-approval gate is enabled)

### Phase 2b — Operations API (Web Development Team, parallel with Phase 2a/2c)
- Build business API endpoints: permits, visits, birds, hazards, tours, locks, content
- Build admin API endpoints: permit approval/rejection, visitor tracking, push notification dispatch, Bluetooth lock management
- Implement the **permit state machine** (§4.3) and the `PermitApprovals` audit table
- Build `/api/notifications/*` endpoints — integrate with Azure Notification Hubs SDK (DevOps Team assists)
- Deploy Operations API schema (Permits, Visits, BirdSightings, Hazards, PermitApprovals)
- Integrate Application Insights telemetry

### Phase 3a — Mobile App (Web Development Team, parallel with Phase 2)
- **Option A:** build native login, registration, and forgot-password screens; implement JWT storage and silent refresh.
- **Option B:** integrate **MSAL.iOS** and **MSAL.Android**; trigger sign-up/sign-in/SSPR user flows; rely on MSAL token cache and silent refresh.
- Build/update permit application, bird sighting, hazard reporting, visit check-in screens
- Integrate Gallagher Bluetooth SDK for gate lock control
- Register for push notifications via Azure Notification Hubs (tag = user id)
- Implement offline content caching (bird lists, site maps, orientation content)

### Phase 3b — Operator Web App (Web Development Team, parallel with Phase 3a)
- Build Operator Web App dashboard (React/Blazor SPA) — permit management with the state machine UX (Submit→UnderReview→Approved/Rejected/InfoRequested), visitor tracking, push notifications, hazard review
- Integrate Entra ID (internal MW tenant) login via MSAL.js
- Connect to admin API endpoints via APIM admin product
- *(Option B only)* Wire Microsoft Graph calls for the account-approval gate, if enabled

### Phase 4 — Integration Testing & Hardening (All Teams)
- End-to-end testing: mobile → Cloudflare → APIM → (Identity API →) Operations API → SQL
- End-to-end testing: operator web app → APIM (direct) → Operations API → SQL
- Verify APIM path-based routing correctly directs `/api/auth/*` and `/api/profile/*` (Option A only) and all other paths to Operations API
- Verify operator web app cannot be reached via Cloudflare public path (admin product IP restriction)
- Penetration testing on the full chain (both public and internal paths)
- Load testing via APIM
- Cloudflare WAF rule tuning
- Geo-fencing validation (AU-only if required)

### Phase 5 — Go-Live & Monitoring (All Teams)
- Production deployment (Operations API, Operator Web App, mobile apps; Identity API under Option A)
- Monitoring dashboards: Cloudflare Analytics, APIM App Insights, SQL Auditing, External ID audit logs (Option B)
- Alerting: failed auth spikes, API error rates, SQL threat detection, overdue permit-approval queue
- User onboarding and permit migration
- Operator training on the admin dashboard

---

## 11. APIM Policy Reference

### 11.1 Public Product — Mobile App, Option A (Custom JWT)

```xml
<inbound>
    <!-- Restrict to Cloudflare IPs -->
    <ip-filter action="allow">
        <address-range from="173.245.48.0" to="173.245.48.255" />
        <!-- Additional Cloudflare IP ranges: https://www.cloudflare.com/ips/ -->
    </ip-filter>

    <!-- Validate custom JWT issued by Identity API -->
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" require-scheme="Bearer">
        <issuer-signing-keys>
            <key>{{jwt-signing-key}}</key>  <!-- Named value from Key Vault -->
        </issuer-signing-keys>
        <audiences>
            <audience>wtp-birdwatching-api</audience>
        </audiences>
        <issuers>
            <issuer>wtp-identity-api</issuer>
        </issuers>
    </validate-jwt>

    <!-- Rate limiting per user -->
    <rate-limit-by-key calls="100" renewal-period="60"
        counter-key="@(context.Request.Headers.GetValueOrDefault("Authorization","").AsJwt()?.Subject)" />
</inbound>
```

### 11.2 Admin Product — Operator Web App (Entra ID JWT)

```xml
<inbound>
    <!-- No Cloudflare IP filter — accepts MW corporate network directly -->

    <!-- Validate Entra ID (internal MW tenant) JWT -->
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" require-scheme="Bearer">
        <openid-config url="https://login.microsoftonline.com/{mw-tenant-id}/v2.0/.well-known/openid-configuration" />
        <audiences>
            <audience>{operator-app-client-id}</audience>
        </audiences>
        <issuers>
            <issuer>https://login.microsoftonline.com/{mw-tenant-id}/v2.0</issuer>
        </issuers>
        <required-claims>
            <claim name="roles" match="any">
                <value>WTP.Operator</value>
            </claim>
        </required-claims>
    </validate-jwt>

    <!-- Rate limiting per operator -->
    <rate-limit-by-key calls="200" renewal-period="60"
        counter-key="@(context.Request.Headers.GetValueOrDefault("Authorization","").AsJwt()?.Claims["oid"]?.FirstOrDefault())" />
</inbound>
```

### 11.3 Public Product — Mobile App, Option B (Entra External ID JWT)

```xml
<inbound>
    <!-- Restrict to Cloudflare IPs (same as Option A) -->
    <ip-filter action="allow">
        <address-range from="173.245.48.0" to="173.245.48.255" />
        <!-- Additional Cloudflare IP ranges: https://www.cloudflare.com/ips/ -->
    </ip-filter>

    <!-- Validate Entra External ID JWT via OIDC discovery -->
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" require-scheme="Bearer">
        <openid-config url="https://{external-id-tenant}.ciamlogin.com/{external-id-tenant-id}/v2.0/.well-known/openid-configuration" />
        <audiences>
            <audience>{operations-api-client-id}</audience>
        </audiences>
        <issuers>
            <issuer>https://{external-id-tenant-id}.ciamlogin.com/{external-id-tenant-id}/v2.0</issuer>
        </issuers>
        <required-claims>
            <claim name="scp" match="any">
                <value>permits.read</value>
                <value>permits.write</value>
            </claim>
        </required-claims>
    </validate-jwt>

    <!-- Rate limiting per user (oid claim) -->
    <rate-limit-by-key calls="100" renewal-period="60"
        counter-key="@(context.Request.Headers.GetValueOrDefault("Authorization","").AsJwt()?.Claims["oid"]?.FirstOrDefault())" />
</inbound>
```

## 12. Appendix

### A. Glossary

| Term | Definition |
|------|-----------|
| **APIM** | Azure API Management — API gateway for policy enforcement, rate limiting, and observability |
| **WAF** | Web Application Firewall — Cloudflare's OWASP rule set for filtering malicious requests |
| **TDE** | Transparent Data Encryption — encrypts Azure SQL data at rest |
| **Managed Identity** | Azure identity for services — eliminates stored connection string credentials |
| **Argon2id** | Password hashing algorithm — recommended by OWASP for secure credential storage |
| **Entra ID** | Microsoft identity platform for internal/corporate users (used for MW staff operator authentication) |

### B. Related Documents

- WTP Birdwatching App AGA Presentation (November 2025)
- WTP Birdwatching Auth Scenarios diagram (WTP_Birdwatching_Auth_Scenarios.drawio)

### C. Entra External ID — see §3

This appendix previously held a forward-looking note on Entra External ID. That content is now part of the main body in **§3 — Authentication Options for External Users** and **§4 — Authentication, User Creation & Approval Flows**, which evaluate External ID as the recommended option (B) alongside SQL custom auth (A) and Azure AD B2C (C).

### D. Decision Log

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Cloudflare as edge security layer | Addresses the "Azure edge security post-April 2026" gap immediately; provides WAF, DDoS, CDN |
| 2 | Azure APIM as API gateway | Richer API policies than Azure Front Door; Cloudflare handles CDN/WAF role |
| 3 | SQL-based authentication for public users | Entra External ID is not yet available within MW and requires additional enablement work; SQL auth allows delivery to proceed now |
| 4 | Azure SQL over MySQL | Better Managed Identity, Entra auth, threat detection, TDE integration; aligns with Azure-first |
| 5 | App Service over Container Apps | Simpler ops for backend APIs; Container Apps if scaling requirements grow |
| 6 | Operator Web App direct to APIM (no Cloudflare) | Internal MW staff on corporate network — no need for public edge security; reduces latency and avoids unnecessary Cloudflare routing |
| 7 | Separate APIM products for public vs admin | Public product (Cloudflare IP-restricted, custom JWT) and admin product (MW network, Entra ID JWT with admin role) enforce least-privilege access |
| 8 | Backend split into Identity API + Operations API | Separation of concerns — auth/profile logic isolated from business logic; enables future migration to Entra External ID by replacing only the Identity API |
| 9 | Web Development Team owns Operations API + mobile + operator web app | Same team builds business API endpoints, mobile apps, and operator web app; provides end-to-end ownership of business logic and UI. DevOps Team owns Identity API, infrastructure, and Azure Notification Hubs integration |
| 10 | Notification Hubs integration shared across teams | DevOps Team provisions and configures Notification Hubs (APNs/FCM credentials, connection strings); Web Development Team builds `/api/notifications` endpoints and mobile push registration, assisted by DevOps on SDK integration |
| 11 | Three external-user auth options evaluated; Entra External ID (Option B) recommended | External ID gives MFA/SSPR/social out of the box, eliminates password-storage liability, and aligns with MW's Entra direction. Option A (SQL) remains the documented fallback if External ID tenancy enablement is not ready by Phase 2 (see §3). |
| 12 | Account-approval gating off by default | Email OTP (Option B) or email verification (Option A) plus the per-permit approval workflow are sufficient gates for Bluetooth-lock entitlement. The optional `AccountApprovals` table / `accountApproved` extension attribute remains available if a sponsor requires it. |
| 13 | Permit state machine `Draft → Submitted → UnderReview → Approved \| Rejected \| InfoRequested → Active → Expired` | Provides explicit, auditable transitions; gates Bluetooth-lock entitlement on `Active`; supports SLA tracking and IRAP-style auditability via the `PermitApprovals` table (see §4.3). |
| 14 | Operator role model: `WTP.Operator` + `WTP.Admin` to start | Single-approver model is sufficient for expected approval volumes; revisit (e.g. Reviewer/Approver maker-checker split) only if volume or compliance requirements change. |
