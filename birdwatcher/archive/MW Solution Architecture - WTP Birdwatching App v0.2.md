# WTP Birdwatching App

Solution Architecture Design (SAD)

Project: WTP Birdwatching App (2026)

Version 0.2, 15/05/2026

Document Classification: Official Sensitive

Author: Rennie LF

Sponsor: Alistair McIntosh (Project Manager)

Sponsoring EA: Gary Franks

## Version History

| Date | Version | Change Summary | Author |
|------|---------|----------------|--------|
| 1/12/2025 | 0.1 | Initial version | GF |
| 15/05/2026 | 0.2 | Expanded production architecture, security model, dual authentication scenarios (SQL custom auth and Entra External ID), APIM policy references, and diagram placeholders | RLF |

## Document Approval

| Date | Approver |
|------|----------|
| TBD | TBD |

## Table of Contents

1. Introduction
2. Solution Outline
3. Target State Architecture
4. Business Architecture
5. Information Architecture
6. Application Architecture
7. Technology Architecture
8. Security Architecture
9. Appendix

---

## 1. Introduction

### 1.1 Purpose

This document details the Solution Architecture Design (SAD) for the WTP Birdwatching mobile app. It supersedes the template-level v0.1 shell with a complete, implementation-ready architecture baseline.

The SAD provides a central reference point for:

- solution building blocks and composition
- design decisions and tradeoffs
- integration boundaries
- security controls and identified gaps
- delivery responsibilities across teams

### 1.2 Audience

This document is primarily aimed at:

- Architecture Governance
- MW Architecture Team
- Project Manager
- Business Stakeholders
- Project Implementation Teams
- Change Advisory Board
- Cyber Security and Identity teams

### 1.3 Stakeholders

| Stakeholder Group | Role |
|------------------|------|
| WTP Operations | Permit approvals, hazard operations, visitor safety coordination |
| Birdwatching Public Users | Permit application, guided onsite access, hazard notifications |
| MW Identity Team | Entra platform enablement, identity policy governance |
| DevOps Team | Platform, APIs, APIM, CI/CD, cloud security controls |
| Web Development Team | Operations API, mobile apps, operator web app UI |
| Cyber Security | Security review, control assurance, penetration testing |

---

## 2. Solution Outline

### 2.1 Architecture Context

The Western Treatment Plant (WTP) is a listed Ramsar wetland and a significant habitat for 300+ bird species. Public birdwatching access currently relies on manual processes and physical keys, which introduces operational friction and safety visibility gaps.

The WTP Birdwatching solution redevelops the current proof-of-concept into production capability with:

- mobile-first permit and visitor workflows
- digital safety and induction content
- real-time hazard and closure notifications
- permit-gated Bluetooth lock access
- operator tooling for approvals, tracking, and communications

### 2.2 Solution Objectives

- Redevelop the PoC into an operational production service
- Improve permit lifecycle management and visitor self-service
- Improve onsite safety communication and visibility
- Replace physical key distribution with controlled Bluetooth lock workflows
- Provide operators with a central dashboard for permit decisions and alerts
- Maintain alignment with MW cloud, API gateway, and identity direction

---

## 3. Target State Architecture

### 3.1 Architecture Overview

> **DIA-01 Placeholder: Target Architecture Overview (Systems Landscape)**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio`

Core request path:

`Mobile App -> Cloudflare -> APIM -> Identity API / Operations API -> Azure SQL`

Internal admin path:

`Operator Web App (MW Corporate Network) -> APIM Admin Product -> Operations API (+ Identity API only for Option A) -> Azure SQL`

### 3.2 Component Summary

| Component | Technology | Purpose |
|-----------|------------|---------|
| Edge Security | Cloudflare | Reverse proxy, WAF, DDoS and bot mitigation, TLS edge control |
| API Gateway | Azure API Management Standard v2 | JWT validation, policy enforcement, throttling, routing, observability |
| Identity API (Option A) | Azure App Service (.NET/Node) | Registration, login, password reset, JWT issuance |
| Operations API | Azure App Service — Elastic Premium EP1 (existing MW plan) | Permits, visits, sightings, hazards, tours, locks, notifications |
| Operator Web App | Azure Static Web App (pure SPA) | Operator permit workflow and operational dashboard |
| Database | Azure SQL Database | Identity and operations data store |
| Notifications | Azure Notification Hubs | APNs/FCM push delivery |
| Secret Management | Azure Key Vault | Signing keys and managed secret references |
| Monitoring | App Insights + Log Analytics | Traces, metrics, logs, alerting |
| Bluetooth | Gallagher integration | Lock trigger operations |

### 3.3 APIM Path Routing

| Path Prefix | Target |
|-------------|--------|
| `/api/auth/*` | Identity API (Option A only) |
| `/api/profile/*` | Identity API (Option A only) |
| `/api/permits/*` | Operations API |
| `/api/visits/*` | Operations API |
| `/api/birds/*` | Operations API |
| `/api/hazards/*` | Operations API |
| `/api/tours/*` | Operations API |
| `/api/locks/*` | Operations API |
| `/api/notifications/*` | Operations API |
| `/api/content/*` | Operations API |

---

## 4. Business Architecture

### 4.1 Business Context

The solution addresses three core business outcomes:

- safer onsite operations through live communication and better operator visibility
- reduced access friction by replacing physical key administration
- improved user experience through mobile self-service permit and visit workflows

### 4.2 Business Process View

High-level process:

1. User registers/signs in
2. User submits permit request
3. Operator reviews and approves/rejects/requests more information
4. User activates permit (including payment where applicable)
5. User accesses site and features, including lock operations under permit entitlement
6. User can report hazards and sightings while operators monitor and respond

### 4.3 Architecturally Significant Business Requirements

- Complete permit decision auditability
- Role-based approval controls
- Reliable emergency notification path
- Enforced lock entitlement based on permit validity
- Mobile support for iOS and Android
- Administrative workflows for operator and admin personas

---

## 5. Information Architecture

### 5.1 Information Overview

Data domains are split into:

- identity and access data (Option A only in SQL)
- operational permit and visit data
- environmental reporting data (birds, hazards)
- notification targeting data

### 5.2 Data Models (Schema Excerpts)

Identity (Option A baseline):

```sql
CREATE TABLE Users (
    Id              INT IDENTITY PRIMARY KEY,
    Email           NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(512) NOT NULL,
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

Operations:

```sql
CREATE TABLE Permits (
    Id              INT IDENTITY PRIMARY KEY,
    UserId          INT NOT NULL,
    PermitType      NVARCHAR(50),
    Status          NVARCHAR(20),
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
    Status          NVARCHAR(20)
);

CREATE TABLE PermitApprovals (
    Id              INT IDENTITY PRIMARY KEY,
    PermitId        INT NOT NULL REFERENCES Permits(Id),
    ApproverId      NVARCHAR(64) NULL,
    Action          NVARCHAR(32) NOT NULL,
    FromState       NVARCHAR(20),
    ToState         NVARCHAR(20),
    Reason          NVARCHAR(1000) NULL,
    Timestamp       DATETIME2 DEFAULT GETUTCDATE()
);
```

### 5.3 Data Migration

- Existing PoC data migration is optional and subject to data quality review.
- At minimum, production cutover requires new user onboarding and permit issuance integrity.
- If Option B is chosen from day one, SQL credential migration is avoided entirely.

### 5.4 Integration Architecture

> **DIA-06 Placeholder: Integration Landscape**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio`

| Integration | Purpose |
|------------|---------|
| Cloudflare -> APIM | Edge filtering and protected origin access |
| APIM -> App Services | Policy-controlled API forwarding |
| APIs -> Azure SQL | Transaction and query operations |
| Operations API -> Notification Hubs | Push dispatch |
| Operations API -> Gallagher | Lock command flow |
| Option A: Identity API -> Email Service | Verification and reset messaging |
| Option B: Mobile App/APIM -> External ID | OIDC token issuance and validation |

---

## 6. Application Architecture

### 6.1 Application Components and Composition

> **DIA-07 Placeholder: Application Components — Integration View**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio` (tab: Application Components — Integration View)

#### 6.1.1 New Applications and Services

All four application components are net-new deliverables. The table below expands each component into its constituent modules and identifies the responsible delivery team.

| Component | Technology | Delivery Team | Internal Modules |
|-----------|-----------|---------------|------------------|
| **Mobile App** (iOS / Android) | TBD — React Native or native Swift / Kotlin (pending Web Dev team decision) | Web Development Team | Auth screens (login, register, forgot password); Permit application flow; Visit check-in / check-out; Bird sighting and hazard reporting; Push notification receiver; Bluetooth lock interaction |
| **Identity API** (Option A only) | Azure App Service — .NET 8+ or Node.js | DevOps Team | User registration; Login and JWT issuance; Refresh token management; Forgot password and email verification; User profile read / update |
| **Operations API** | Azure App Service — .NET 8+ or Node.js; hosted on existing Elastic Premium EP1 plan (`func-prd-ae-ais-asp`) | DevOps Team | Permit CRUD and state transitions; Visit management; Bird sightings; Hazard reporting and triage; Virtual guided tours; Bluetooth lock commands; Notification dispatch (Notification Hubs integration); Site content delivery; Admin endpoints (operator web app backend) |
| **Operator Web App** | Azure Static Web App — React or Blazor WASM (pure SPA) | Web Development Team | Permit approval dashboard; Visitor tracking and active visit view; Hazard triage and status management; Broadcast push notification UI; Bluetooth lock administration |

#### 6.1.2 Existing Applications and Services Being Retired

| Application | Status | Notes |
|-------------|--------|-------|
| WTP Birdwatching PoC | **Retired** — replaced in full | The existing proof-of-concept application is decommissioned on production cutover. No data migration is mandated; existing PoC user records are subject to a data quality review before any selective migration is considered. |

#### 6.1.3 Design Time View

The solution is divided between two delivery teams with a clear API boundary at APIM.

| Boundary | DevOps Team | Web Development Team |
|----------|-------------|----------------------|
| Infrastructure | Azure APIM, App Service plans, Azure SQL, Key Vault, Notification Hubs, App Insights, Cloudflare origin setup, CI/CD pipelines | — |
| Identity (Option A) | Identity API (full ownership — auth, JWT, profile) | Auth screens in Mobile App consume Identity API endpoints |
| Business logic | APIM policies, routing, and throttling configuration; Operations API (all business domains) | Mobile App, Operator Web App UI |
| Notifications | Azure Notification Hubs integration on Operations API `/api/notifications` endpoint | Mobile App push-notification registration and receipt; notification dispatch UI in Operator Web App |

API contracts between components are enforced at APIM. Each team is responsible for maintaining their component's OpenAPI specification and publishing it to the APIM developer portal.

#### 6.1.4 Run Time View

The following integration paths are active at runtime:

| Integration | Direction | Protocol / Auth |
|------------|-----------|------------------|
| Mobile App → Cloudflare → APIM → Identity API | Outbound (Option A auth only) | HTTPS; unauthenticated on `/api/auth/*` (pre-login) |
| Mobile App → Cloudflare → APIM → Operations API | Outbound (all business calls) | HTTPS; Bearer JWT validated at APIM boundary |
| Identity API → Azure SQL | Outbound | Private endpoint; Managed Identity or connection string via Key Vault |
| Operations API → Azure SQL | Outbound | Private endpoint; Managed Identity or connection string via Key Vault |
| Operations API → Azure Notification Hubs | Outbound (push dispatch) | Managed Identity; APNs and FCM fan-out to registered mobile devices |
| Operations API → Gallagher | Outbound (lock command) | Internal MW network call; protocol TBD with Gallagher integration team |
| Identity API → Email Service | Outbound (Option A only) | SMTP or transactional email API; used for verification and password reset |
| Operator Web App → Entra ID (MW internal tenant) | Outbound (operator auth) | MSAL.js; OIDC Authorization Code flow |
| Operator Web App → APIM Admin Product → Operations API | Outbound (admin operations) | HTTPS; Entra ID Bearer JWT with `WTP.Operator` role claim validated at APIM |

#### 6.1.5 Deployment View

| Component | Azure Hosting | Network Zone | CI/CD |
|-----------|--------------|--------------|-------|
| Mobile App | App Store (iOS) / Google Play (Android) | Client device — calls Cloudflare edge IPs | Mobile build pipeline (Xcode / Gradle); app binary signed and submitted per platform |
| Identity API (Option A) | Azure App Service (B1/S1, scalable) | VNet-integrated; accessible only via APIM | DevOps pipeline; deployment slot swap for zero-downtime releases |
| Operations API | Azure App Service — Elastic Premium EP1 (existing plan: `func-prd-ae-ais-asp` prod / `func-devtest-ase-ais-asp` dev-test) | VNet-integrated (regional); private endpoint for inbound; accessible only via APIM | DevOps pipeline; ZIP/code deploy with deployment slot swap for zero-downtime releases |
| Operator Web App | Azure Static Web App (SPA) | MW corporate network → APIM Admin Product; no Cloudflare | Web Development team pipeline for SPA build and deployment; DevOps pipeline for hosting infrastructure |
| Azure SQL | SQL Database (S0/S1 with TDE) | Private endpoint only — no public access | Schema migrations via pipeline-executed migration scripts |
| APIM | Standard v2 | Cloudflare IP allowlist (public product); MW corporate IP (admin product) | DevOps pipeline; policies deployed as code |
| Key Vault | Standard tier | Private access from App Services and APIM via Managed Identity | Managed through infrastructure pipeline |
| Notification Hubs | Standard tier | Called from Operations API | Configuration managed in DevOps pipeline |

### 6.2 Permit Workflow State Machine

> **DIA-05 Placeholder: Permit State Machine and Approval Workflow**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio`

State model:

`Draft -> Submitted -> UnderReview -> Approved/Rejected/InfoRequested -> Active -> Expired`

Rules:

- Only operator/admin roles can transition review states.
- All state transitions are recorded in `PermitApprovals`.
- Lock operations require permit ownership and active validity window.

### 6.3 User Interaction, Usability, Accessibility

- Mobile-first design for field use and intermittent connectivity
- Accessibility-aligned forms and readable safety messaging
- Minimal operator clicks for high-volume permit decisions

---

## 7. Technology Architecture

### 7.1 Technology Components and Composition

> **DIA-08 Placeholder: Technology Components View**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio` (tab: Technology Components)

#### 7.1.1 New Technology and Platform Services

All components below are net-new for this solution. None were present in the PoC.

| Component | Type | Description | Solution Impact |
|-----------|------|-------------|------------------|
| **Cloudflare** (Pro or higher) | Edge Security / CDN | Reverse proxy with WAF (OWASP ruleset), DDoS protection, bot detection, rate limiting, and TLS termination. Sits in front of APIM for all public mobile traffic. Origin certificate configured to restrict APIM to Cloudflare IPs only. | New. Acts as the interim enterprise edge control while MW’s native Azure edge security strategy matures. Provides immediate OWASP and DDoS coverage without dependency on enterprise edge readiness timeline. |
| **Azure API Management** (Standard v2) | API Gateway | Centralised policy enforcement: JWT validation, Cloudflare IP allowlisting, per-user rate limiting, path-based routing to Identity API and Operations API, request schema validation, and APIM Product separation (Public / Admin). Observability via App Insights. | New. Mandatory gateway for all inbound API traffic. Enforces security baseline, provides audit trail, and decouples clients from backend hosting changes. |
| **Microsoft Entra External ID** | Identity — Consumer IdP | Cloud-hosted external identity provider for public birdwatcher authentication (Option B — recommended). Supports OIDC Authorization Code + PKCE flow via MSAL. Maintains a consumer-facing directory separate from the MW corporate Entra ID tenant. Supports social and guest identities. | New. Recommended authentication option. Replaces the custom Identity API credential store (Option A) if adopted. APIM validates resulting JWTs against the Entra External ID OIDC discovery endpoint. |
| **Azure App Service** (Elastic Premium EP1 — existing MW plans) | Compute — PaaS | Platform-as-a-Service hosting for both the Operations API and Identity API (Option A). Existing Elastic Premium EP1 plans (`func-prd-ae-ais-asp` in Australia East, `func-prd-ase-ais-asp` in Australia Southeast for DR, `func-devtest-ase-ais-asp` for dev/test) are reused — no new App Service plan provisioning required. VNet integration (regional) provides outbound routing to SQL and Key Vault private endpoints. Private endpoint on each Web App restricts inbound access to APIM only. Deployment slots provide zero-downtime releases. | Existing — reused. Existing approved compute platform within the MW tenancy. Eliminates new platform onboarding, subnet provisioning, and firewall rule changes that would be required for a first Container Apps environment. |
| **Azure Static Web App** (Standard) | Compute — Static Hosting | CDN-backed hosting for the Operator Web App SPA (React or Blazor WASM). No server-side runtime. Integrates with Entra ID (MW internal tenant) for operator authentication via MSAL.js. | New. Hosts the Operator Web App. |
| **Azure SQL Database** (S0/S1) | Data — Relational Database | Primary relational data store for all application data: identity credentials and profiles (Option A), permits, visits, bird sightings, hazards, and approval audit trail. TDE enabled at rest. Private endpoint only — no public access. | New. Replaces any unmanaged PoC data store. Private endpoint and TDE enforced from initial deployment. Schema changes delivered via pipeline-executed migration scripts. |
| **Azure Key Vault** (Standard) | Security — Secret Management | Secure vault for signing keys, connection strings, and API secrets. Referenced by APIM as named values and accessed by App Service via Managed Identity — no credentials stored in application configuration. | New. Not present in PoC. Centralises secret lifecycle and eliminates hardcoded credentials from application and infrastructure code. |
| **Azure Notification Hubs** (Standard) | Integration — Push Notifications | Fan-out push notification service supporting APNs (iOS) and FCM (Android). Called by Operations API `/api/notifications/*` to dispatch operator-initiated alerts and hazard notifications to registered mobile devices. | New. Not present in PoC. Enables real-time safety and operational push notifications from WTP operators to field visitors. |
| **App Insights + Log Analytics** | Observability | Centralised telemetry platform. App Insights attached to APIM and both backend APIs for distributed traces, performance metrics, and exception logging. Log Analytics as the backing workspace for alert rules, dashboards, and security event retention. | New. Not present in PoC. Provides operational visibility, SLA monitoring, and security investigation capability across the full request path. |

#### 7.1.2 Existing Technology and Platform Services Being Modified

| Component | Type | Description | Solution Impact |
|-----------|------|-------------|------------------|
| **MW Entra ID** (internal MW tenant) | Identity — Corporate IdP | MW’s existing Microsoft Entra ID tenant used for internal employee identity and access management. | Modified. Extended to support the Operator Web App authentication flow. The `WTP.Operator` and `WTP.Admin` app roles are added to the tenant for RBAC enforcement via APIM. No changes to existing tenant configuration beyond app registration and role definition. |

#### 7.1.3 Technology Being Retired

| Component | Type | Retirement Notes |
|-----------|------|------------------|
| WTP Birdwatching PoC application stack | Ad-hoc / PoC | Retired on production cutover. All data, hosting, and configuration from the PoC is superseded by the production components listed above. |

### 7.2 Environments and Zones

- Development
- Staging
- Production

Network segregation and private data access controls are applied progressively across environments.

### 7.3 Capacity Plan

- Start with moderate baseline SKUs and monitor APIM, API, and SQL utilization trends.
- Scale API and database independently based on transaction profile.
- Use API gateway throttling to shape bursts and protect backend consistency.

### 7.4 Business Continuity, Backup, Resilience, Availability

- App Service deployment slots (Identity API); Azure Container Apps revision traffic splitting for zero-downtime deployments (Operations API)
- Azure SQL backups with optional geo-replication strategy
- Cloudflare edge resilience and failover characteristics
- Centralized alerting on auth failures, API errors, and queue/backlog risk signals

---

## 8. Security Architecture

### 8.1 Network Security

> **DIA-02 Placeholder: Network Security Request Flows (Public and Internal)**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio`

Public mobile flow:

`Internet -> Cloudflare -> APIM Public Product (Cloudflare IP allowlist) -> Container Apps internal ingress (VNet-injected) -> Azure SQL Private Endpoint`

Internal operator flow:

`MW Corporate Network -> APIM Admin Product -> Operations API (Container Apps internal ingress) -> Azure SQL Private Endpoint`

Controls:

- Cloudflare TLS and WAF controls at edge
- APIM product separation for public and admin access
- Container Apps internal ingress — no public endpoint; accessible only within the VNet-injected Container Apps Environment from APIM
- SQL private endpoint only (no public exposure)
- TDE enabled for data at rest

### 8.2 Application Security

#### 8.2.1 Authentication Options

| Criterion | Option A - SQL Custom Auth | Option B - Entra External ID (Recommended) |
|----------|-----------------------------|---------------------------------------------|
| Delivery readiness | Available now | Depends on tenant enablement |
| Password liability | High (MW stores hashes) | None (Microsoft-managed identity platform) |
| MFA / SSPR | Custom build required | Built-in configuration |
| Social sign-in | Not native | Supported |
| Auth maintenance burden | High | Low |
| Strategic alignment | Interim | Preferred target state |

##### Option A: SQL Custom Auth (Buildable Baseline)

> **DIA-03 Placeholder: Auth Scenario A - SQL Custom Auth**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio`

Summary:

- Identity API handles register/login/verify-email/forgot-password/refresh-token.
- Passwords hashed using Argon2id and salted.
- Access tokens are self-signed JWTs validated by APIM.

APIM policy (Public Product, Option A):

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

Key risks under Option A:

- credential custody and breach liability remains with MW
- MFA and SSPR become custom engineering backlog
- long-term auth feature maintenance overhead

##### Option B: Microsoft Entra External ID (Recommended)

> **DIA-04 Placeholder: Auth Scenario B - Entra External ID**
>
> Insert diagram export from: `WTP_Birdwatching_Auth_Scenarios.drawio`

Summary:

- Mobile app uses MSAL (OIDC Authorization Code + PKCE).
- APIM validates tokens via OIDC discovery endpoint.
- Identity API is reduced to profile-only scope or removed.

APIM policy (Public Product, Option B):

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

Advantages supporting recommendation:

- no password storage in solution data plane
- built-in MFA, SSPR, and identity controls
- reduced custom auth code footprint and operational risk
- lower recurring platform cost in expected MAU band

Constraint:

- depends on MW External ID tenancy enablement timeline

##### Option C: Azure AD B2C (Fallback)

Use only if External ID enablement is blocked. Functional capability is similar, but strategic direction favors External ID for net-new customer identity builds.

##### Recommendation Matrix

| Condition | Recommended Action |
|-----------|--------------------|
| External ID enabled in time | Deliver directly on Option B |
| External ID delayed | Release with Option A and plan cutover to B |
| External ID not feasible | Use Option C before committing to long-term Option A |

#### 8.2.2 Authorisation and RBAC

| Role | Scope |
|------|-------|
| WTP.User | End-user permit and visit actions |
| WTP.Operator | Permit review, hazard operations, notifications |
| WTP.Admin | Elevated administration and support functions |

APIM policy (Admin Product, Entra ID JWT):

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

### 8.3 Information Security

#### 8.3.1 Data Security

This section covers controls applied to application data at each state: at rest, in transit, and at the logical access layer.

##### Data at Rest

| Data Store | Classification | Control |
|---|---|---|
| Azure SQL Database | Official Sensitive | Transparent Data Encryption (TDE) enabled with service-managed keys. Private endpoint only — no public network access. Database firewall denies all non-VNet traffic. |
| Azure Key Vault | Official Sensitive | Secrets and keys stored in FIPS 140-2 Level 1 validated HSM-backed service (Standard tier). Access restricted to Managed Identity principals only — no shared key access. Soft-delete and purge protection enabled. |
| Application Insights / Log Analytics | Official Sensitive | Telemetry data retained in the MW Azure tenancy. Workspace-level access control applied. Data export and cross-workspace access disabled unless explicitly approved. |
| Mobile device local storage | Sensitive | Access tokens and refresh tokens stored in the platform keychain (iOS Keychain, Android Keystore). No credentials stored in shared app preferences or unencrypted local storage. |

**Data classification note:** Permit records, visit logs, and bird sighting data are classified Official Sensitive due to their potential to reveal visitor location and access patterns to a heritage-listed site. Health or safety-critical data (hazard reports) is treated equivalently.

##### Data in Transit

All inter-component communication is encrypted in transit. The following controls apply per hop:

| Hop | Protocol | Control |
|---|---|---|
| Mobile App → Cloudflare | TLS 1.2 minimum (TLS 1.3 preferred) | Certificate pinning recommended for production iOS/Android builds |
| Cloudflare → APIM | TLS 1.2+ | Cloudflare origin certificate presented to APIM; APIM configured to accept only from Cloudflare IP ranges |
| APIM → Container Apps (Operations API) | HTTPS within VNet | Internal VNet ingress — traffic does not traverse public internet |
| APIM → App Service (Identity API, Option A) | HTTPS | TLS enforced; outbound to VNet-integrated App Service |
| Container Apps / App Service → Azure SQL | TLS 1.2+ over private endpoint | Private DNS zone resolves `*.database.windows.net` to private endpoint IP; no path to public SQL endpoint |
| App Service / Container Apps → Key Vault | HTTPS over private endpoint or service tag | Managed Identity bearer token on all requests; no shared access signatures |
| Operations API → Notification Hubs | HTTPS (AMQP/HTTPS SDK) | Azure SDK manages TLS; connection string stored in Key Vault |
| Operator Web App → APIM | HTTPS | Standard v2 APIM custom domain with managed certificate; HSTS enforced |

##### Security Privileges and Attribute-Based Access Control

Access to application resources is governed by the principle of least privilege and role-based attributes.

**API-level authorisation:**

| JWT Claim | Source | Enforced By | Effect |
|---|---|---|---|
| `roles: WTP.Operator` | MW Entra ID (internal tenant) | APIM Admin Product policy | Required for all operator-facing endpoints (`/api/permits/*/state`, `/api/hazards/*/triage`, `/api/locks/*`) |
| `roles: WTP.Admin` | MW Entra ID (internal tenant) | APIM Admin Product policy + Operations API middleware | Required for broadcast notifications and elevated support functions |
| `sub` / `oid` (public user identity) | Entra External ID (Option B) or Identity API (Option A) | APIM Public Product policy + Operations API middleware | Restricts data access to resources owned by the authenticated user (e.g., own permits, own visits) |

**Data-layer isolation:** The Operations API enforces row-level ownership checks — a public user may only read or modify permit or visit records where their `userId` / `oid` matches the record owner. Operator-scope endpoints are routed via a separate APIM product and require the `WTP.Operator` role claim in addition to a valid JWT.

**Infrastructure RBAC:** Azure RBAC is applied at the resource group level. Managed Identities are used for all service-to-service access (Container Apps → Key Vault, Container Apps → SQL, App Service → Key Vault). No human accounts are granted standing access to production Key Vault secrets or SQL databases. Just-in-time (JIT) access is expected to be governed through MW's existing PIM policies.

---

#### 8.3.2 Credential Stores and Certificate Management

##### Key Vault Structure

A single Azure Key Vault (Standard tier) is provisioned within the solution resource group. It holds:

| Secret / Key Name | Type | Consumer | Rotation Approach |
|---|---|---|---|
| `jwt-signing-key` | Secret (symmetric) | Identity API (Option A), APIM named value | Manual rotation via pipeline with APIM named value update; deprecated on migration to Option B |
| `apim-subscription-key` (internal) | Secret | Internal service-to-service calls where API keys are used | Rotated quarterly or on breach indicator |

> **Note — SQL and Notification Hubs:** Neither Azure SQL nor Azure Notification Hubs requires a stored secret when Container Apps authenticate via Managed Identity. SQL connections use Entra-integrated authentication (`Authentication=Active Directory Managed Identity` in the connection string — no password). Notification Hubs SDK supports `DefaultAzureCredential`, eliminating the SAS connection string. No rotation is required for either because no static credential exists.

All application code retrieves secrets at startup via Managed Identity using the Azure SDK (`DefaultAzureCredential`). No secrets are embedded in `appsettings.json`, environment variable literals in container definitions, or pipeline variables in plain text.

##### TLS Certificates

| Surface | Certificate Type | Issuer | Notes |
|---|---|---|---|
| APIM custom domain (public) | Managed certificate (Azure-issued) | DigiCert via Azure | Auto-renewed. Custom domain configured on APIM gateway endpoint. |
| APIM → Cloudflare origin | Cloudflare Origin Certificate | Cloudflare CA | 15-year validity; not publicly trusted — only used for Cloudflare-to-APIM leg. Renewed via Cloudflare dashboard. |
| Static Web App (Operator) | Managed certificate | Azure Front Door / Static Web Apps | Auto-renewed. |
| Internal VNet communication | Service-managed (Azure platform TLS) | Microsoft | No manual certificate management required for internal traffic. |

##### MW Security Guidelines for Certificate Procurement

Certificate procurement for public-facing endpoints must follow MW's existing PKI and Certificate Authority policy. Where Azure-managed certificates are used, their automated renewal removes the procurement dependency for standard cases. Any certificate requiring an externally-trusted CA outside Azure-managed issuers must be submitted via the MW PKI request process and stored in Key Vault with expiry alerting configured in Log Analytics.

**Expiry alerting:** A Log Analytics alert rule must be configured to fire 60 days before any Key Vault certificate expiry. This alert routes to the DevOps team distribution list.

---

#### 8.3.3 Integration Security

This section categorises the integration patterns in scope by transport security, session authentication, and key storage.

##### Transport Layer Security (Host-to-Host)

All external-facing integration endpoints enforce a minimum of TLS 1.2. TLS 1.0 and 1.1 are disabled on APIM, App Service, and Container Apps by platform configuration or policy. The internal VNet paths (APIM → Container Apps, Container Apps → SQL private endpoint) are protected by the Azure network boundary in addition to TLS.

Cloudflare acts as the TLS termination point for public mobile traffic. The re-encryption leg from Cloudflare to APIM uses an origin certificate, ensuring end-to-end encryption with no plaintext hop at the reverse proxy.

| Integration | Direction | TLS Minimum | Notes |
|---|---|---|---|
| Mobile App ↔ Cloudflare | Inbound public | TLS 1.2 | Cloudflare enforces minimum TLS version in dashboard settings |
| Cloudflare ↔ APIM | Server-to-server | TLS 1.2 | Origin certificate; Cloudflare IP allowlist enforced at APIM |
| Operator Web App ↔ APIM | Inbound internal | TLS 1.2 | Via MW corporate network (VPN or ExpressRoute); no Cloudflare on this path |
| APIM ↔ Container Apps | Internal VNet | TLS 1.2 | Internal ingress only; no public endpoint on Container Apps |
| Container Apps ↔ Azure SQL | Internal VNet | TLS 1.2 | Private endpoint; Encrypt=True enforced in connection string |
| Operations API ↔ Notification Hubs | Outbound | TLS 1.2 | Azure SDK manages; Managed Identity (`DefaultAzureCredential`) — no SAS token required |

##### Session Authentication

Authentication mechanisms differ by user population:

**Public mobile users (birdwatchers):**

- **Option A:** Custom JWT issued by the Identity API following email/password validation. Token lifetime: 15 minutes (access) / 30 days (refresh). Refresh token stored in `RefreshTokens` SQL table and rotated on each use (refresh token rotation). JWT signed with HMAC-SHA256 using a Key Vault-backed signing key.
- **Option B (recommended):** OIDC Authorization Code + PKCE flow via MSAL (iOS: `MSAL.iOS`, Android: `MSAL.Android`). Entra External ID issues access and ID tokens. APIM validates via OIDC discovery document (`/.well-known/openid-configuration`). No credential material touches the solution data plane.

**Internal operators (MW staff):**

- Entra ID (internal MW tenant) with MSAL.js (Authorization Code + PKCE from the Operator Web App SPA).
- APIM Admin Product validates the Entra ID JWT and enforces the `WTP.Operator` role claim before forwarding to the Operations API.
- No separate session is maintained by the application — stateless JWT validation on each request.

**Service-to-service:**

- Managed Identity bearer tokens (via Azure platform token endpoint) for all service-to-service calls: Container Apps → Key Vault, App Service → Key Vault, App Service → SQL (where Entra-integrated SQL auth is used).
- No shared secrets or API keys for internal platform integration. Azure SQL uses Entra-integrated authentication (Managed Identity) — no password. Notification Hubs SDK supports `DefaultAzureCredential` — no SAS connection string required. Neither service needs a secret stored in Key Vault or a rotation process.

##### Key Store (Credential Storage)

| Credential Type | Storage Location | Access Method |
|---|---|---|
| JWT signing key (Option A) | Azure Key Vault | Identity API via Managed Identity at startup |
| APIM named values (Key Vault references) | Key Vault (backed) | APIM resolves at policy runtime via Managed Identity |
| SQL access | No secret — Managed Identity | Container Apps authenticate to SQL via Entra-integrated auth; no credential stored or rotated |
| Notification Hubs access | No secret — Managed Identity | Operations API uses `DefaultAzureCredential`; no SAS connection string stored or rotated |
| Public user passwords (Option A only) | Azure SQL (`Users` table) | Argon2id hash + per-user salt; plaintext never persisted |
| Operator credentials | MW Entra ID (not MW-managed storage) | Delegated to Microsoft identity platform |
| Public user credentials (Option B) | Entra External ID (not in solution data plane) | Delegated to Microsoft identity platform |
| Mobile app tokens | iOS Keychain / Android Keystore | MSAL SDK manages secure storage |

---

### 8.4 Security Requirements and Gaps

#### Requirements

| Requirement | Control | Status |
|---|---|---|
| Data at rest encryption | TDE on Azure SQL; Key Vault for secrets | Met |
| Data in transit encryption | TLS 1.2+ enforced on all hops | Met |
| No hardcoded credentials | All secrets in Key Vault; Managed Identity access | Met |
| API gateway enforcement | APIM with product-level policy (IP filter, JWT validation, rate limiting) | Met |
| Network isolation for backend services | Container Apps internal ingress; SQL private endpoint | Met |
| Audit trail for permit state changes | `PermitApprovals` table with actor `oid`, state, timestamp | Met |
| Role-based access enforcement | APIM Admin Product + Operations API role checks | Met |
| Credential breach liability minimisation | Option B (Entra External ID) — no passwords in solution | Met (Option B); partial (Option A) |
| MFA for operators | Entra ID Conditional Access (MW corporate) | Met |
| MFA for public users | Built-in (Option B); not available (Option A) | Gap under Option A |

#### Identified Gaps

**Option A specific:**

- **No native MFA for public users.** The custom Identity API has no built-in second factor. Implementing TOTP or SMS OTP would require additional build effort, third-party integration, and ongoing maintenance. This represents an elevated credential risk compared to Option B.
- **Credential breach liability.** Password hashes for public users reside in the MW Azure tenancy. A SQL breach would require mandatory breach disclosure obligations under the Privacy Act 1988. Argon2id mitigates cracking risk but does not eliminate liability.
- **SSPR is a custom build.** Forgot-password flows, email verification links, and token expiry handling are bespoke code subject to implementation error.
- **No refresh token revocation on breach.** Under Option A, if a user's refresh token is compromised, revocation requires direct SQL intervention. No native revocation list mechanism exists in the custom implementation.

**Option B specific:**

- **Tenant enablement dependency.** Entra External ID must be provisioned within the MW Azure tenancy before Option B can be delivered. This is a platform readiness gate outside the project's direct control.
- **Custom policy complexity.** If account approval gating (operator review before first login) is required, it must be implemented via Entra External ID custom policies (CIAMPOL). This requires Identity team engagement and testing time.

**Shared gaps:**

- **Cloudflare as interim compensating control.** Azure-native edge security (Azure Front Door with WAF, DDoS Network Protection) would be the preferred long-term control. Cloudflare is used as an interim measure pending alignment with the MW enterprise edge roadmap. A migration plan from Cloudflare to the Azure-native equivalent should be produced when the enterprise roadmap timing is confirmed.
- **Penetration testing not yet scheduled.** The production architecture has not been subject to external penetration testing. A penetration test must be completed before production cutover, with findings triaged and resolved as a prerequisite to go-live sign-off. This is logged as a dependency in the RAID register.
- **Certificate expiry alerting not yet implemented.** Automated Key Vault certificate expiry alerts must be configured in Log Analytics as part of the DevOps hardening stream. Until this is in place, certificate expiry is a manual tracking risk.
- **Existing PoC cyber design gaps.** The proof-of-concept environment did not apply the security controls described in this document. A security hardening workstream must be completed before any PoC components are promoted to production.

---

## 9. Appendix

### 9.1 RAID: Risks, Assumptions, Issues, Dependencies

| Type | Item | Impact | Mitigation |
|------|------|--------|------------|
| Risk | Auth pathway complexity and drift | High | Strong API contracts, stage-gated integration tests |
| Risk | Permit approval queue backlog | Medium | Dashboard SLA alerts and operational runbooks |
| Assumption | MW tenancy and required subscriptions remain available | Medium | Early environment and identity readiness checks |
| Dependency | External ID enablement decision | High | Phase gate with fallback to Option A/C path |
| Issue | Existing PoC cyber design gaps | High | Security hardening stream before production cutover |
| Dependency | Container Apps Environment VNet injection availability in target subscription and region | Medium | Validate regional support and quota early; fallback to App Service if blocked |

### 9.2 Architecture Decision Summary

| Decision ID | Decision | Rationale |
|-------------|----------|-----------|
| DEC-01 | Host in MW Azure tenancy | Security, governance, operational alignment |
| DEC-02 | Auth strategy supports Option A baseline and Option B target | Delivery continuity with strategic identity direction |
| DEC-03 | Cloudflare as interim edge security control | Compensates until enterprise edge roadmap timing aligns |
| DEC-04 | APIM Standard v2 as mandatory gateway | Central policy, routing, observability, and control enforcement |
| DEC-05 | Azure Container Apps for Operations API hosting | KEDA-based autoscaling, revision traffic splitting, and VNet-injected internal ingress align with scaling and security requirements; reduces always-on cost at low traffic via Consumption plan scale-to-zero |

### Glossary

| Term | Definition |
|------|------------|
| APIM | Azure API Management |
| CIAM | Customer Identity and Access Management |
| OIDC | OpenID Connect |
| PKCE | Proof Key for Code Exchange |
| MSAL | Microsoft Authentication Library |
| MAU | Monthly Active Users |
| TDE | Transparent Data Encryption |
| WAF | Web Application Firewall |
| SSPR | Self-Service Password Reset |

### References

1. MW Solution Architecture - WTP Birdwatching App v0.1
2. WTP_Birdwatching_App_Proposal.md
3. WTP_Birdwatching_App_Presentation.md
4. WTP_Birdwatching_Auth_Scenarios.drawio
