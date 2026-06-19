# Melbourne Water — Entra External ID Operations Guide

**Tenant:** `melbwaterext.onmicrosoft.com`  
**Date:** June 2026  
**Author:** AIS Team  
**Audience:** MW Entra ID Support Team  
**Status:** Draft

---

## Overview

Microsoft Entra External ID is Melbourne Water's external-facing identity platform — separate from the internal MW corporate Entra ID tenant. It provides authentication and identity management for public users and external consumers of MW digital services.

The **WTP Birdwatching App** is the first application to consume this tenant. Subsequent applications should follow the same pattern documented here.

| Item | Value |
|------|-------|
| Tenant name | `melbwaterext.onmicrosoft.com` |
| Tenant type | External (CIAM — Customer Identity and Access Management) |
| Relationship to MW corporate tenant | Completely separate — no user or group sync |
| Who authenticates here | Public users (birdwatchers, permit applicants, external visitors) |
| Who does NOT authenticate here | MW staff and operators (they use the internal MW Entra ID tenant) |

---

## Part 1 — Initial Setup (One-Time)

### 1.1 Create the External Tenant

This is done once by the MW identity/platform team via the Azure portal.

1. Sign in to [portal.azure.com](https://portal.azure.com) with a Global Administrator account in the **MW corporate subscription**
2. Search for **Microsoft Entra External ID** → **Create an external tenant**
3. Fill in:
   - **Tenant name:** `Melbourne Water External`
   - **Domain name:** `melbwaterext` *(resulting in `melbwaterext.onmicrosoft.com`)*
   - **Location:** Australia (data residency)
   - **Subscription:** Link to the appropriate MW subscription (Shared Services recommended)
4. Complete creation — takes 2–5 minutes
5. Switch directory context to `melbwaterext.onmicrosoft.com` to continue configuration

> **Note:** The External tenant is billed through the linked Azure subscription. Ensure this is the MW Shared Services subscription, not a project subscription.

---

### 1.2 Configure Tenant Branding

1. In the `melbwaterext.onmicrosoft.com` tenant, go to **Company Branding**
2. Set:
   - Organisation name: `Melbourne Water`
   - Logo: MW logo (PNG, max 245×36px)
   - Sign-in page background: MW branded background or plain white
   - Favicon: MW favicon
3. These appear on all login pages across every application using this tenant

---

### 1.3 Configure Authentication Methods

1. Go to **Authentication methods** → **Policies**
2. Enable **Email one-time passcode (OTP)** — this is the primary MFA method for external users
   - No phone number or Microsoft Authenticator required
   - User receives a 6-digit code to their email at every sign-in
3. Disable **Password** if email OTP only is the desired flow (passwordless)
   - If email + password is preferred, enable both and set MFA to required
4. Disable social identity providers (Google, Facebook) unless explicitly approved by MW Cybersecurity

> **Recommendation:** Start with email OTP only (passwordless). Simpler for users, no password reset support burden, and aligns with MW's MFA posture.

---

## Part 2 — Registering the First Application (WTP Birdwatcher)

Each application that uses this tenant requires its own **App Registration**. Follow this process for the Birdwatcher app and repeat for every new application onboarded.

### 2.1 Create the App Registration

1. In `melbwaterext.onmicrosoft.com` → **App registrations** → **New registration**
2. Fill in:
   - **Name:** `WTP Birdwatcher - Mobile App`
   - **Supported account types:** Accounts in this organizational directory only (melbwaterext only)
   - **Redirect URI:** Platform = **Public client/native (mobile & desktop)**; URI = `msauth://com.melbournewater.birdwatcher/callback` *(confirm bundle ID with mobile dev team)*
3. Click **Register**
4. Note the **Application (client) ID** — the mobile team will need this for MSAL configuration

### 2.2 Add API Scope (for APIM JWT Validation)

This exposes a named permission that the mobile app requests and APIM validates.

1. In the app registration → **Expose an API**
2. Set **Application ID URI:** `api://birdwatcher`
3. Add scopes:

| Scope name | Display name | Who can consent | Purpose |
|---|---|---|---|
| `api.access` | Access Birdwatcher API | Admins and users | General API access — used by APIM `validate-jwt` |

4. Click **Save**

### 2.3 Grant the App Permission to its Own Scope

1. In the app registration → **API permissions** → **Add a permission**
2. Select **My APIs** → `WTP Birdwatcher - Mobile App` → select `api.access`
3. Click **Add permissions**
4. Click **Grant admin consent for melbwaterext** → Confirm

### 2.4 Configure User Flows

User flows define what the sign-in / sign-up experience looks like.

1. Go to **User flows** → **New user flow**
2. Select **Sign up and sign in**
3. Name: `B2C_1_birdwatcher_signup_signin` *(naming convention: `B2C_1_<appname>_<flow>`)*
4. Identity providers: **Email one-time passcode**
5. User attributes to collect at sign-up:

| Attribute | Collect | Return in token |
|---|---|---|
| Display name | ✅ Yes | ✅ Yes |
| Email address | ✅ Yes (verified) | ✅ Yes |
| Given name | Optional | Optional |
| Surname | Optional | Optional |

6. Click **Create**
7. Link the user flow to the app registration under **Applications** within the flow

---

## Part 3 — OIDC Metadata (for APIM and Developers)

Once the tenant and app registration are created, the following endpoints are used by APIM and by developers integrating with the tenant.

| Item | Value |
|------|-------|
| OIDC discovery URL | `https://melbwaterext.ciamlogin.com/<tenant-id>/v2.0/.well-known/openid-configuration` |
| Issuer | `https://melbwaterext.ciamlogin.com/<tenant-id>/v2.0` |
| JWKS URI | Found in OIDC discovery doc |
| Token endpoint | `https://melbwaterext.ciamlogin.com/<tenant-id>/oauth2/v2.0/token` |
| Authorisation endpoint | `https://melbwaterext.ciamlogin.com/<tenant-id>/oauth2/v2.0/authorize` |

> Replace `<tenant-id>` with the Directory (tenant) ID from the tenant overview page in the portal.

The AIS team will need the **OIDC discovery URL** and **Application (client) ID** to configure the APIM `validate-jwt` policy.

---

## Part 4 — Daily Operations and BAU

### 4.1 User Management

#### Viewing registered users

1. In `melbwaterext.onmicrosoft.com` → **Users** → **All users**
2. Users are created automatically on first sign-up via the user flow — no manual provisioning required
3. Each user has a stable **Object ID (OID)** — this is the key used to link the user to their data in application databases

#### Disabling a user account

If a user reports abuse, a compromised account, or needs to be blocked:

1. **Users** → find the user → **Edit properties** → **Settings** → set **Account enabled** to No
2. The user will be unable to sign in immediately
3. Any active sessions will be invalidated within the token lifetime (up to 60 minutes) unless revoked immediately (see below)

#### Revoking all active sessions immediately

```
Users → [select user] → Revoke sessions
```

This invalidates all refresh tokens immediately. The user's next API call will fail and they will be forced to re-authenticate (which will fail if the account is also disabled).

#### Deleting a user

1. **Users** → find user → **Delete**
2. Deleted users are soft-deleted and remain in the **Deleted users** view for 30 days — can be restored within that window
3. After 30 days, permanently deleted — all authentication data removed
4. **Note:** Deleting from Entra External ID does NOT delete the user's application data (permits, sightings, etc.) from the Azure SQL database. Application data deletion must be handled separately by the application team per MW data retention policy.

---

### 4.2 Application Registration Management

#### Adding a new application to the tenant

Each new MW application that requires external user authentication must go through this process:

1. Create a new App Registration (follow Section 2.1–2.4 above)
2. Create a new User Flow if the sign-up experience differs from existing flows
3. Provide the Application (client) ID and OIDC discovery URL to the application team
4. Document the registration in the [Application Register](#application-register) below

#### Rotating app credentials

Entra External ID uses PKCE (Proof Key for Code Exchange) for mobile and SPA clients — **no client secret is stored in the mobile app**. There are no secrets to rotate for the mobile app registration.

If a confidential client (server-side) is ever registered, client secrets must be rotated before expiry:

1. App registration → **Certificates & secrets** → **New client secret**
2. Set expiry (maximum 24 months)
3. Copy the new secret value immediately — it is only shown once
4. Update the consuming application's Key Vault reference
5. Delete the old secret after confirming the new one is working

#### Monitoring secret expiry

Set a calendar reminder 60 days before any client secret expiry date. There is no automatic alert from Entra External ID for secret expiry.

---

### 4.3 Authentication Method Changes

To add or remove an identity provider or change MFA settings:

1. **Authentication methods** → **Policies**
2. Changes take effect immediately for new sign-in attempts
3. Existing sessions are not affected until token expiry or revocation
4. Coordinate with the application team before changing identity providers — mobile apps may require an app update if MSAL configuration changes

---

### 4.4 Monitoring and Audit Logs

#### Sign-in logs

1. `melbwaterext.onmicrosoft.com` → **Monitoring** → **Sign-in logs**
2. Shows all authentication attempts — successful, failed, and interrupted
3. Filter by application, user, date range, or status
4. Useful for diagnosing user login issues and detecting unusual sign-in patterns

#### Audit logs

1. **Monitoring** → **Audit logs**
2. Records all administrative actions: user creation/deletion, app registration changes, policy changes
3. Retention: 30 days in portal (export to Log Analytics for longer retention — recommended)

#### Connecting to Log Analytics (recommended — set up on day one)

```
Monitoring → Diagnostic settings → Add diagnostic setting
  → Send to Log Analytics workspace
  → Select: SignInLogs, AuditLogs
  → Save
```

Use the MW Shared Services Log Analytics workspace. This enables:
- Retention beyond 30 days
- KQL queries and alerts
- Integration with existing MW monitoring dashboards

#### Key alerts to configure in Log Analytics

| Alert | KQL signal | Recommended threshold |
|---|---|---|
| High sign-in failure rate | `SignInLogs | where ResultType != 0` | >50 failures in 5 minutes from single IP |
| Account disabled sign-in attempt | `SignInLogs | where ResultType == 50057` | Any occurrence |
| Admin action outside business hours | `AuditLogs | where TimeGenerated !between (8h .. 18h)` | Any occurrence |

---

### 4.5 Responding to User Issues

#### User cannot receive OTP email

1. Check **Sign-in logs** for the user — confirm the attempt reached Entra External ID
2. Ask the user to check spam/junk folder
3. OTP emails come from `no-reply@melbwaterext.onmicrosoft.com` — may need whitelisting with some email providers
4. If persistent: **Users** → find user → **Authentication methods** → confirm email address is correct

#### User locked out / too many failed attempts

Entra External ID applies smart lockout automatically. If a user is locked:

1. **Users** → find user → check account status
2. Wait 30 seconds (first lockout) — lockout duration increases with repeated failures
3. If account is not disabled and lockout clears, the user can retry
4. If an admin reset is needed: **Users** → **Reset password** (if password auth is enabled)

#### User says they signed up but cannot access the app

1. Confirm the user completed sign-up fully (OTP verified)
2. Check **Users** in the portal — user should appear with a verified email
3. Check the application's database — the user's OID should be present if they've previously logged in and the app created their profile
4. If the OID is missing from the database, the user may be signing in with a different email — check **Sign-in logs** for their OID

---

## Part 5 — Application Register

Maintain this table as new applications are onboarded to the tenant.

| Application | App Registration Name | Client ID | User Flow | Date Registered | Owner Team |
|---|---|---|---|---|---|
| WTP Birdwatcher (Mobile) | `WTP Birdwatcher - Mobile App` | *(set at registration)* | `B2C_1_birdwatcher_signup_signin` | TBC | AIS Team / DevOps |

---

## Part 6 — Escalation and Support Contacts

| Issue | Contact |
|---|---|
| Tenant provisioning / licensing | MW Identity Platform Team |
| Application onboarding (new app registration) | MW Entra ID Support Team + AIS Team |
| User account issues (lockout, deletion) | MW Entra ID Support Team |
| APIM JWT policy update (new tenant OIDC URL) | AIS Team |
| Mobile app MSAL configuration | Web Development Team |
| Microsoft support (platform-level issues) | Raise via Azure Portal → Support + billing → New support request, selecting the `melbwaterext.onmicrosoft.com` tenant |

---

## Part 7 — Quick Reference Checklist

### New application onboarding checklist

- [ ] Create App Registration in `melbwaterext.onmicrosoft.com`
- [ ] Set Application ID URI and expose API scope
- [ ] Create User Flow (or reuse existing if experience is identical)
- [ ] Grant admin consent for the scope
- [ ] Provide Client ID + OIDC discovery URL to application team
- [ ] Confirm APIM `validate-jwt` policy updated with new app's audience
- [ ] Add entry to Application Register (Part 5)
- [ ] Confirm Log Analytics diagnostic settings capture sign-in logs for the new app

### New tenant setup checklist (one-time)

- [ ] External tenant created at `melbwaterext.onmicrosoft.com`
- [ ] Tenant linked to MW Shared Services subscription
- [ ] Company branding configured (MW logo, colours)
- [ ] Email OTP authentication method enabled
- [ ] Password auth policy confirmed (enabled or disabled per MW Cybersecurity decision)
- [ ] Diagnostic settings configured → MW Log Analytics workspace
- [ ] Tenant ID recorded and shared with AIS Team for APIM configuration
- [ ] First app registration created (Birdwatcher)
