# Change Request — Entra External ID Tenant Setup & App Registration

**Document Version:** 2.0
**Date:** 22 June 2026
**Author:** AIS Team
**Status:** Draft for Review

---

## Scope

Provision and baseline-configure the Microsoft Entra External ID tenant, its user-facing
sign-in experience, **and the application registrations** for the WTP Birdwatching App.

To reduce the number of change requests, the previously separate app-registration work is
consolidated into this CR. It now covers, in a single change:

- **Tenant foundation** — tenant provisioning, admin governance, security baseline,
  custom attributes, branding, user flows, and logging.
- **App registrations** — mobile public client, operator app, API scope
  `Birdwatcher.Operations.ReadWrite`, redirect URIs, app-to-user-flow association,
  admin consent, and handoff of OIDC metadata to the mobile/APIM teams.

The work is sequenced so the tenant foundation is established and validated first, then
the application registrations are bound to the existing user flows.

---

## Design Alignment

This CR implements the full **Stream B — Entra External ID Setup** work described in the
Scenario B delivery plan, combining tenant configuration and app registration into one
change:

- **Tenant setup:** custom attributes → identity providers → user flows
  (sign-up email OTP, sign-in, SSPR/password reset, profile edit) → branding → MFA →
  logging.
- **App registration:** register the public mobile client + operator app, redirect URIs,
  API scope `Birdwatcher.Operations.ReadWrite`, associate apps to the user flows, grant
  consent, hand OIDC metadata URL + client ID to the mobile/APIM teams.

---

## Implementation Plan

### Provisioning

1. Create resource group `rg-hub-ase-extid` in subscription `0.MelbWater-Shared-Svcs`
   (region: Australia Southeast). Apply MW tagging/naming standards.
2. Azure Portal → Create resource → Microsoft Entra External ID.
3. Create new external tenant `melbwaterext` (→ `melbwaterext.onmicrosoft.com`),
   linked to `0.MelbWater-Shared-Svcs` and `rg-hub-ase-extid`.
   - Confirm and record the tenant **data residency location** (immutable after creation).
4. Confirm **MAU billing model** and link billing to the subscription;
   create a Cost Management budget + alert.

### Identity & Admin Governance

5. Coordinate with IDAM to provision admin accounts and assign roles per governance.
6. Create **break-glass / emergency access accounts** in the external tenant.
7. Enforce **MFA, Conditional Access, and PIM** on all administrative roles.

### Security Baseline (agreed with Cybersecurity)

8. Configure **authentication methods**: Email OTP for end users
   (confirm whether social IdPs are in/out of scope).
9. Apply **external collaboration policies** and **end-user MFA baseline**.
10. Configure **token/session lifetimes** and tenant-level **Conditional Access**.

### Sign-in Experience (tenant-scoped)

11. Define **custom user attributes**: `vehicleRego`, `displayName`, `accountApproved`.
12. Apply **company branding** (logo, colours, sign-in page).
13. Create **user flows**:
    - Sign-up (Email OTP, collecting custom attributes)
    - Sign-in
    - Password reset (SSPR)
    - Profile edit
14. Validate user flows in dev (initially against a temporary test application;
    re-validated against the real registrations below once created).

### Observability

15. Configure **diagnostic settings** to stream sign-in + audit logs to
    Log Analytics / Microsoft Sentinel.

### App Registrations

App registrations are delivered **dev-first**: the dev mobile app registration and its
backing API registration are created and validated end-to-end before the operator app and
any UAT/Production registrations are raised. Each environment gets its own registrations
(no shared dev/prod app objects).

#### 16. Operations API registration (dev) — backing resource for the scope

The mobile client cannot request `Birdwatcher.Operations.ReadWrite` until an API exposes
it. Create this registration first.

16.1. Entra admin centre (external tenant) → **App registrations** → **New registration**.
16.2. Name: `birdwatcher-api-dev`. Supported account types: **Accounts in this
      organizational directory only** (this external tenant).
16.3. Leave redirect URI blank (this is a resource API, not an interactive client).
16.4. After creation, go to **Expose an API**:
      - Set the **Application ID URI** (e.g. `api://birdwatcher-api-dev` or the
        verified-domain form).
      - **Add a scope** → `Birdwatcher.Operations.ReadWrite`:
        - Who can consent: **Admins only**.
        - Admin consent display name/description: "Read and write Birdwatcher
          operations data".
        - State: **Enabled**.
16.5. Record the **Application (client) ID** and **Application ID URI** for the mobile
      registration and the APIM `validate-jwt` audience.

#### 17. Dev Birdwatcher mobile app registration (public client)

17.1. **App registrations** → **New registration**.
17.2. Name: `birdwatcher-mobile-dev`. Supported account types: **Accounts in this
      organizational directory only**.
17.3. **Platform configuration** → **Add a platform** → **Mobile and desktop
      applications**:
      - iOS redirect URI: `msauth.<iOS-bundle-id>://auth`
        (e.g. `msauth.au.com.melbournewater.birdwatcher.dev://auth`).
      - Android redirect URI: `msauth://<android-package>/<base64-signature-hash>`.
      - Optionally add `http://localhost` for local dev/test harnesses.
17.4. **Authentication** → enable **Allow public client flows** = **Yes**
      (native app, no client secret / PKCE-based).
17.5. **API permissions** → **Add a permission** → **My APIs** → `birdwatcher-api-dev`
      → **Delegated permissions** → select `Birdwatcher.Operations.ReadWrite`.
17.6. **Grant admin consent** for the external tenant on the added permission.
17.7. **Token configuration** → add the custom-attribute / optional claims the app needs
      (e.g. `displayName`, `vehicleRego`) so they appear in the ID/access token.
17.8. Record the **Application (client) ID**, **Directory (tenant) ID**, and configured
      redirect URIs.

#### 18. Associate the dev mobile app to the user flows

18.1. Entra admin centre → **External Identities** → **User flows** → select the
      sign-up/sign-in flow.
18.2. **Applications** → **Add application** → select `birdwatcher-mobile-dev`.
18.3. Confirm the SSPR and profile-edit flows are reachable from the same flow
      configuration.

#### 19. Operator web app registration (deferred to operator delivery)

> The operator dashboard registration (confidential client, redirect/sign-out URIs, app
> roles) follows the same pattern but is raised when the operator web app build starts.
> Listed here for completeness; not required for the dev mobile validation.

19.1. Register `birdwatcher-operator-dev` as a **confidential client** (web platform) with
      redirect + front-channel sign-out URIs.
19.2. Assign the required app roles / delegated permissions per the operator design.
19.3. Grant admin consent.

### Validation & Sign-off

20. Validate tenant is accessible via the portal and via
    https://melbwaterext.ciamlogin.com (External ID endpoint).
21. Run an **end-to-end MSAL sign-up/sign-in** against `birdwatcher-mobile-dev`
    (or a temporary MSAL test client using the same registration), confirming:
    - The user flow renders with MW branding and collects custom attributes.
    - The issued access token has the correct **audience** (`birdwatcher-api-dev`),
      **scope** (`Birdwatcher.Operations.ReadWrite`), and custom-attribute claims.
22. Obtain **Cybersecurity sign-off** on branding, MFA policy, and user-flow config.

### Handoff to Mobile / APIM Teams

23. Record and hand over the **OIDC metadata URL, tenant ID, mobile client ID, and API
    application ID URI** so the APIM `validate-jwt` policy can be pre-populated and the
    mobile team unblocked.

---

## References

- [Plan a CIAM Deployment — Microsoft Entra External ID | Microsoft Learn](https://learn.microsoft.com/en-us/entra/external-id/customers/concept-planning-your-solution)
- [React SPA using MSAL React against Microsoft Entra External ID — Code Sample | Microsoft Learn](https://learn.microsoft.com/en-us/samples/azure-samples/ms-identity-ciam-javascript-tutorial/ms-identity-ciam-javascript-tutorial-1-sign-in-react/)
- WTP Birdwatching App — Scenario B Direct Delivery Plan (`archive/WTP_Birdwatching_Phased_Auth_Delivery_Plan.md`)
- WTP Birdwatching Auth Scenarios diagram (`WTP_Birdwatching_Auth_Scenarios.drawio`)
