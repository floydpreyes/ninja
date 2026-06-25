# Microsoft Entra External ID — Design & Implementation

**Solution:** WTP Birdwatching App
**Document Version:** 1.0
**Date:** 23 June 2026
**Author:** AIS Team
**Audience:** MW Operations, IDAM, Cybersecurity, Architecture Governance
**Status:** Draft for Review

---

## 1. Purpose

This document describes the design and implementation of a Microsoft Entra External ID
(CIAM) tenant for the WTP Birdwatching App. It is the reference for the Operations team to
understand how the external identity platform is provisioned, secured, and consumed by the
application.

It covers:

- Tenant topology and provisioning
- How the Birdwatching app utilises External ID (sign-up, sign-in, token flow)
- External user sign-up experience
- Initial admin security setup
- Conditional Access design (public-user vs admin)
- User flow configuration
- Logging, monitoring, and operational ownership

> **Scope note:** This is the production-target identity design. It corresponds to
> **Stream B — Entra External ID** of the Scenario B delivery plan
> (`archive/WTP_Birdwatching_Phased_Auth_Delivery_Plan.md`). The detailed change steps are
> tracked separately in `WTP_Birdwatching_ExternalID_Tenant_Setup_CR.md`.

---

## 2. Background & Design Decision

The WTP Birdwatching App serves **members of the public** who hold (or apply for) permits to
visit the Western Treatment Plant. These users are **external consumers**, not Melbourne
Water staff, so they must not be created in the internal MW workforce tenant.

**Scenario B (Entra External ID)** was selected as the sole production identity approach. It:

- Eliminates custom identity code (no Identity API, no SQL password storage, no custom JWT
  signing/lockout/reset logic).
- Delegates credential security, MFA, and self-service password reset to Microsoft.
- Issues standards-based OIDC tokens (RS256) that APIM validates at the gateway.
- Provides built-in sign-up, sign-in, MFA (Email OTP), and optional social identity
  providers.

---

## 3. Tenant Topology

External ID runs as a **separate directory** from the internal Melbourne Water workforce
Entra ID tenant. The two are distinct identity boundaries.

> **[DIAGRAM PLACEHOLDER — Tenant Topology]**
> Insert the **"Tenant Topology"** page exported from
> `WTP_Birdwatching_ExternalID_Diagrams.drawio` here when converting to DOCX.
> _Shows the MW workforce tenant and the external (CIAM) tenant as separate directories,
> linked by B2B guest invitation of existing admin accounts, with subscription / resource
> group / region / billing facts._

| Attribute | Value |
|-----------|-------|
| External tenant domain | `melbwaterext.onmicrosoft.com` |
| Login endpoint | `https://melbwaterext.ciamlogin.com` |
| Subscription | `0.MelbWater-Shared-Svcs` |
| Resource group | `rg-hub-ase-extid` |
| Region / data residency | Australia (confirmed at creation — **immutable**) |
| Billing model | MAU-based (first 50k MAU free, then per-MAU) |

---

## 4. Tenant Creation

1. Create resource group `rg-hub-ase-extid` in subscription `0.MelbWater-Shared-Svcs`
   (region: Australia Southeast), tagged per MW standards.
2. Azure Portal → **Create resource** → **Microsoft Entra External ID**.
3. Create a new **external tenant** with domain name `melbwaterext`
   (→ `melbwaterext.onmicrosoft.com`), linked to the subscription and resource group.
4. Confirm and record the **data residency location** (Australia) — this is immutable after
   creation.
5. Confirm the **MAU billing model** and link to the subscription; create a Cost Management
   budget and alert.
6. Validate the tenant is reachable via the Entra admin centre and via
   `https://melbwaterext.ciamlogin.com`.

---

## 5. How the Birdwatching App Uses External ID

### 5.1 Components

| Component | Registration | Client type | Role |
|-----------|-------------|-------------|------|
| Birdwatcher mobile app (iOS/Android) | `birdwatcher-mobile-<env>` | Public client (native, PKCE) | End-user sign-up/sign-in via MSAL |
| Operations API | `birdwatcher-api-<env>` | Web API (resource) | Exposes scope `Birdwatcher.Operations.ReadWrite` |
| Operator dashboard (web) | `birdwatcher-operator-<env>` | Confidential/SPA | Staff admin UI (HTTPS redirect URIs) |

> Each environment (dev / UAT / prod) gets its own registrations — no shared app objects.

### 5.2 Authentication & token flow

```
 Mobile App (MSAL)
    |  (1) Sign-up / sign-in user flow  --> Entra External ID (Microsoft-hosted)
    |      OIDC + PKCE; Email OTP MFA
    |      Returns signed bearer token (RS256, External ID issuer)
    |
    |  (2) API call with Bearer {External ID JWT}
    v
 Cloudflare (WAF/TLS) --> Border Firewall --> ExpressRoute --> Azure Firewall
    |
    v
 Azure APIM  -- validate-jwt against External ID OIDC discovery endpoint
    |          (issuer, audience = birdwatcher-api, RS256)
    v
 Operations API (App Service) -- auth-provider agnostic; trusts APIM
```

Key points for Operations:

- The mobile app authenticates **directly** with External ID (out-of-band from MW
  infrastructure). MW never sees or stores user passwords.
- APIM enforces authentication using the External ID **OIDC discovery URL**; the Operations
  API itself does not validate tokens.
- No JWT signing keys are stored in Key Vault — External ID uses Microsoft-managed keys.

### 5.3 Sample usage patterns

**Pattern A — New public user (first-time visitor)**
1. User installs the app and selects "Sign up".
2. MSAL launches the External ID **sign-up user flow** (system browser / embedded).
3. User enters email → receives **Email OTP** → verifies.
4. User completes profile attributes (e.g. display name, vehicle registration).
5. External ID creates the account; app receives ID + access tokens.
6. App calls the Operations API with the bearer token.

**Pattern B — Returning user (sign-in)**
1. User opens the app; MSAL has a cached account or triggers the **sign-in user flow**.
2. User authenticates (and is challenged for MFA only when required — see §8).
3. App silently acquires a token (refresh token) for subsequent API calls.

**Pattern C — Forgotten password (self-service)**
1. User selects "Forgot password" on the sign-in page.
2. External ID **SSPR** flow verifies identity via email and resets the credential.
3. No MW operator involvement — fully self-service.

**Pattern D — Profile update**
1. User edits profile in-app → **profile-edit user flow** → attributes updated in directory.

---

## 6. External User Sign-Up

### 6.1 Identity providers (initial)

| Provider | Status | Notes |
|----------|--------|-------|
| Email + One-Time Passcode (OTP) | **Enabled (baseline)** | Primary sign-up/sign-in method |
| Email + password | Optional | Decide with Cyber; OTP-only reduces credential risk |
| Google / Apple (social) | Optional / future | Listed in design as optional; confirm scope |

### 6.2 Custom user attributes

Defined at tenant level **before** building user flows that collect them:

| Attribute | Purpose |
|-----------|---------|
| `displayName` | User-facing name |
| `vehicleRego` | Vehicle registration for site access/safety |
| `accountApproved` | Optional approval state flag |

### 6.3 Sign-up experience

- MW company **branding** (logo, colours, sign-in page) applied at tenant level.
- Email OTP verification on sign-up.
- Custom attributes collected during the sign-up flow.
- Account created in the external directory; no MW workforce footprint.

---

## 7. Initial Admin Security Setup

### 7.1 Admin identity model

The External ID tenant is a **separate directory**, so internal MW admin accounts do not
exist there automatically. Two complementary mechanisms are used:

| Mechanism | Use | Notes |
|-----------|-----|-------|
| **B2B guest invite** of existing MW admin accounts | Day-to-day app & tenant administration | Admins keep their MW credentials/MFA; assigned roles or per-app ownership in the external tenant |
| **Cloud-only accounts** native to the external tenant | **Break-glass / emergency access** only | Excluded from CA blocking policies; stored securely; monitored |

> Inviting a guest only places the identity in the directory. Managing app registrations
> additionally requires a **role** (e.g. Application Administrator / Cloud Application
> Administrator) or **per-app Owner** assignment.

### 7.2 Role assignment

| Role | Scope | Assigned to |
|------|-------|-------------|
| Application Administrator / Cloud Application Administrator | Manage all app registrations & consent | AIS/IDAM admins (PIM-eligible) |
| App registration **Owner** | Per-app (least privilege) | AIS team for Birdwatcher apps |
| Global Administrator | Tenant-wide (minimise) | Break-glass accounts + minimal named admins |

### 7.3 Admin protections

- **MFA enforced** on all administrative roles (separate from end-user MFA baseline).
- **PIM** (Privileged Identity Management) for just-in-time, time-bound role activation.
- **Conditional Access** requiring MFA for all admin sign-ins.
- **Break-glass accounts** excluded from CA blocking, with strong credentials and alerting
  on use.

> Confirm with IDAM/Cyber whether MW policy permits assigning privileged directory roles to
> **guest** users; some authorization policies restrict this. If restricted, use PIM-eligible
> assignments or dedicated admin accounts.

---

## 8. Conditional Access Design

The CIAM goal is **fraud/abuse protection and securing admins** — **not** restricting
legitimate public users. The Birdwatching app targets the general public on **unmanaged
personal devices**, so device-based and blanket controls are deliberately avoided for end
users.

### 8.1 Two populations, two postures

| | Tenant admins | End users (public birdwatchers) |
|---|---|---|
| CA posture | Strict | Minimal / risk-based only |
| MFA | Always required | Step-up only (risk-based); Email OTP at sign-up |
| Device controls | Optional (managed) | **Never** — unmanaged phones |
| Goal | Protect privileged access | Protect accounts without friction |

### 8.2 End-user CA policies (minimal, risk-based)

| Policy | Condition | Control |
|--------|-----------|---------|
| **Risky sign-in step-up** | Sign-in risk = medium/high | Require MFA (Email OTP) |
| **High user-risk remediation** | User risk = high (e.g. leaked credentials) | Block or force secure password reset (SSPR) |
| **Session bound** | All end-user sessions | Sign-in frequency / refresh-token lifetime cap |

### 8.3 Explicitly NOT applied to public users

- Require compliant / hybrid-joined / managed device (phones aren't MDM-enrolled).
- Blanket "require MFA for every sign-in" (kills low-friction CIAM experience).
- Hard geographic block (public app; travellers exist — treat geography as a risk signal at
  most, confirm with Cyber).

### 8.4 Admin CA policies (strict)

| Policy | Condition | Control |
|--------|-----------|---------|
| Admin MFA | Any administrative role sign-in | Require MFA (always) |
| Admin session | Admin sessions | Short sign-in frequency |
| Break-glass exclusion | Emergency accounts | Excluded from blocking policies; alert on sign-in |

> **Licensing note:** Risk-based policies require Microsoft Entra ID Protection availability
> in the external tenant. Confirm with IDAM. If risk signals are unavailable, fall back to
> Email-OTP-at-sign-up plus session controls and keep blanket MFA off for end users.

---

## 9. User Flow Configuration

User flows are **tenant-scoped** assets that define the end-user experience. They are created
independently of any app, then associated to one or more app registrations.

> **[DIAGRAM PLACEHOLDER — User Flows]**
> Insert the **"User Flows"** page exported from
> `WTP_Birdwatching_ExternalID_Diagrams.drawio` here when converting to DOCX.
> _Shows the mobile app (MSAL) invoking the four tenant-scoped user flows
> (sign-up, sign-in, SSPR, profile edit) against the External ID tenant, with the
> configuration sequence._

| User flow | Purpose | Key configuration |
|-----------|---------|-------------------|
| **Sign-up** | New public user registration | Email OTP, collect custom attributes (`displayName`, `vehicleRego`) |
| **Sign-in** | Returning user authentication | Email OTP; risk-based MFA step-up |
| **Password reset (SSPR)** | Self-service credential reset | Email verification |
| **Profile edit** | Update profile attributes | Editable custom attributes |

Configuration sequence:

1. Define **custom user attributes** (prerequisite for flows that collect them).
2. Apply **company branding**.
3. Create the **user flows** above.
4. **Associate** the app registrations (mobile, operator) to the relevant user flows.
5. Validate each flow in dev (initially against a temporary test app, then the real
   registrations).

---

## 10. Logging, Monitoring & Operations

| Area | Configuration |
|------|---------------|
| Sign-in & audit logs | **Diagnostic settings** stream External ID sign-in + audit logs to Log Analytics / Microsoft Sentinel |
| Application telemetry | Application Insights (Operations API) correlated with External ID audit logs |
| Cost | Cost Management budget + alert on MAU consumption |
| Identity Protection | Risk detections surfaced for CA and SOC review (if licensed) |

### 10.1 Operational ownership

| Responsibility | Owner |
|----------------|-------|
| Tenant & app registration administration | AIS / IDAM (PIM-eligible roles) |
| Break-glass account custody | IDAM / Cybersecurity |
| Conditional Access policy changes | Cybersecurity + IDAM (change-controlled) |
| User flow / branding changes | AIS (Cyber sign-off) |
| Monitoring / SOC | Cybersecurity (Sentinel) |
| End-user support (sign-up/reset issues) | Operations service desk (escalate to IDAM) |

---

## 11. Validation & Sign-Off

- Tenant reachable via portal and `https://melbwaterext.ciamlogin.com`.
- End-to-end MSAL sign-up/sign-in against the dev mobile registration, confirming token
  **audience**, **scope** (`Birdwatcher.Operations.ReadWrite`), and custom-attribute claims.
- APIM `validate-jwt` validates External ID tokens against the OIDC discovery endpoint.
- **Cybersecurity sign-off** on branding, MFA policy, Conditional Access, and user-flow
  configuration.

---

## 12. References

- [Plan a CIAM Deployment — Microsoft Entra External ID](https://learn.microsoft.com/en-us/entra/external-id/customers/concept-planning-your-solution)
- [Register an app — Microsoft Entra External ID](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?toc=/entra/external-id/toc.json)
- [Add your application to a user flow](https://learn.microsoft.com/en-us/entra/external-id/customers/how-to-user-flow-add-application)
- [Set up an Android app to sign in users (External tenant)](https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-mobile-app-android-prepare-app?tabs=external-tenant)
- [Using redirect URIs with MSAL for iOS and macOS](https://learn.microsoft.com/en-us/entra/msal/objc/redirect-uris-ios)
- [React SPA using MSAL React against Microsoft Entra External ID](https://learn.microsoft.com/en-us/samples/azure-samples/ms-identity-ciam-javascript-tutorial/ms-identity-ciam-javascript-tutorial-1-sign-in-react/)
- WTP Birdwatching App — Scenario B Direct Delivery Plan (`archive/WTP_Birdwatching_Phased_Auth_Delivery_Plan.md`)
- WTP Birdwatching External ID Tenant Setup & App Registration CR (`WTP_Birdwatching_ExternalID_Tenant_Setup_CR.md`)
- WTP Birdwatching External ID Diagrams — tenant topology & user flows (`WTP_Birdwatching_ExternalID_Diagrams.drawio`)
- WTP Birdwatching Auth Scenarios diagram (`WTP_Birdwatching_Auth_Scenarios.drawio`)
