__Birdwatcher – AIS team effort estimates__

__Specifications__

__Background__

The WTP Birdwatching App is a mobile\-first platform \(iOS and Android\) enabling members of the public to apply for birdwatching permits, access wetland areas at Western Treatment Plant via Bluetooth\-controlled Gallagher locks, and submit bird sighting records\. An internal Operator Web App provides Melbourne Water staff with permit queue management, visitor tracking, push notification control, and lock administration\.

The platform routes all public mobile traffic through Cloudflare \(WAF / DDoS / CDN\) into Azure API Management, which enforces JWT validation, rate limiting, and path\-based routing to backend App Services\. Backend business logic is served by a Node\.js Operations API hosted on Azure App Service, with Azure SQL as the primary data store \(private endpoint\), Azure Notification Hubs for push alerts \(APNs and FCM\)\. 

Two authentication scenarios are in scope:

- __Scenario A \-\- SQL Auth__: A custom Identity API handles registration, login, password hashing, refresh token rotation, and JWT issuance\. Passwords are stored in Azure SQL\. The JWT signing key is stored in Key Vault\. This introduces a custom security component that must be owned, patched, and secured by the DevOps team\.
- __Scenario B \-\- Entra External ID \(recommended\)__: Microsoft\-hosted identity for public users via a dedicated External ID tenant \(separate from the internal MW tenant\)\. Eliminates the Identity API entirely, removes SQL password storage, and replaces custom JWT logic with OIDC\-based token validation in APIM\. MSAL is adopted in the mobile app\.

__Scope of Works__

The scope of this project includes:

- __Design and Implementation__ of secure Azure environments across Melbourne Water\-controlled subscriptions for Dev, Test, UAT, Production, and DR\.
- __Infrastructure as Code__ for all Azure resources \(Bicep\), deployed via Azure DevOps pipelines with managed identity \(no stored credentials\)\.
- __Identity and Authentication__ implementation \-\- SQL Auth \(Scenario A\) or Entra External ID \(Scenario B\)\.
- __API Development__ \-\- Identity API \(Scenario A only\) and Operations API \(both scenarios\)\.
- __APIM Configuration__ \-\- products, policies, JWT validation, path routing, rate limiting, and IP restrictions\.
- __CI/CD Pipelines__ for all APIs, infrastructure, and database migrations across all environments\.
- __Integration__ with Cloudflare, Gallagher Bluetooth SDK, Azure Notification Hubs \(APNs and FCM\), and Entra ID \(internal MW tenant for operators\)\.
- __Validation and Testing__ including mobile team API handoff, integration testing cycles, and security review\.
- __Knowledge Transfer and Documentation__ for ongoing AIS team support\.

  
The following tables detail what will be provisioned and the estimated effort required for delivery\. Estimates assume two DevOps/Integration Engineers working in parallel\.  
  
__SCENARIO A – SQL AUTH__

__Name__

__Notes__

__Estimate \(Days\)__

Infrastructure \(IaC\)

Resource Groups for each environment \(dev, test, uat, prod, dr\)\. Azure resources \(App Services,  Azure SQL Server and Database with private endpoint, Key Vault,  APIM instance \(dev uat, and prod\),  Azure Static Web App for Operator Web App, Application Insights and Log Analytics Workspace, Notification Hubs namespace and hub\. All resources written as Bicep and deployed via pipeline\.

5

SQL Schema

Auth schema: Users, RefreshTokens, UserProfiles, AccountApprovals \(optional operator gating\)\.   
Data schema: Permits, PermitApprovals \(full audit log\), Visits, BirdSightings, Content and others

6

Identity API

Authentication endpoints: register, login, forgot/reset password, verify email, refresh token \(sliding window rotation with reuse revocation\)\. Profile read/update \(GET/PUT /api/profile\)\. Middleware: per\-IP rate limiting on login, JWT validation on protected routes\. Unit tests for all auth logic\. Key Vault secret fetch at startup via managed identity\.

12

Operations API

Permits Operator state transitions role\-gated to WTP\.Operator\. Visits, bird sightings, hazards, tours, and static content endpoints\. Swagger/OpenAPI spec published to APIM developer portal\.

18

APIM Configuration

Path routing Entra ID JWT validation \(internal tenant, WTP\.Operator role claim required\), rate limiting per operator\. Named Values configured as Key Vault references\. Backend configuration for both App Services\. OpenAPI specs imported for both APIs\.

5\.5

Entra ID 

Operator App Registration\. App registration in MW internal Entra ID tenant\. Define app roles: WTP\.Operator and WTP\.Admin\. Assign roles to Melbourne Water staff security groups\. Configure APIM Admin Product to validate against internal tenant issuer and audience\. Configure Operator Web App SPA redirect URIs\.

1

CI/CD Pipelines

IaC, Identity, Operations, Static Web App, Database across DevTest, UAT, Prod and DR\. All deployments use managed identity – no stored service principal secrets\.

4

Notification Hubs Integration

Configure Notification Hubs namespace and hub per environment\. Register APNs \(iOS\) and FCM \(Android\) credentials \(provided by mobile team\)\. Tag strategy: userId:\{n\} per registered user\. Operations API integration for operator\-triggered push dispatch\. Email fallback logic via Azure Communication Services for notifications unacknowledged after 24 hours\.

1\.5

Key Vault Configuration

Provision Key Vault per environment\. Secrets stored: JWT signing key \(HS256\), SQL connection strings, Azure Communication Services connection key, Notification Hubs connection string\. APIM Named Values configured to reference Key Vault secrets directly\. App Services configured with Key Vault references in app settings \(no plaintext secrets\)\. Managed identity RBAC configured with Key Vault Secrets User role for all consumers\.

1\.5

Security and Network Controls

Private endpoint for Azure SQL with no public network access\. VNet integration for both App Services to SQL\. App Service access restriction to APIM outbound IPs only \-\- no direct internet access to APIs\. TLS enforced on all endpoints\.

Included in IaC

Monitoring and Alerting

Application Insights connected to both APIs and APIM with distributed tracing\. Log Analytics Workspace as centralised log sink\. Alerts configured for: HTTP 5xx error spike\. 

1\.5

Integrating Testing with Mobile Team

Publish Swagger/OpenAPI specs to APIM developer portal\. Provide dev environment base URL and test credentials to mobile team\. Coordinate mobile team testing of all auth flows \(register, login, forgot\-password, token refresh, JWT attachment to API calls\)\. Bug fix cycle following initial integration\. 

3

Documentation and Handover

Architecture decision record for SQL Auth approach and documented migration path to Entra External ID\. API endpoint reference for internal teams\. CI/CD pipeline documentation\. 

3

__62__

__SCENARIO B – ENTRA External ID__

__Name__

__Notes__

__Estimate \(Days\)__

Infrastructure \(IaC\)

Resource Groups for each environment \(dev, test, uat, prod, dr\)\. Azure resources \(App Services,  Azure SQL Server and Database with private endpoint, Key Vault,  APIM instance \(dev uat, and prod\),  Azure Static Web App for Operator Web App, Application Insights and Log Analytics Workspace, Notification Hubs namespace and hub\. All resources written as Bicep and deployed via pipeline\.

5

Entra External ID – Tenant Setup

Provision External ID tenant within MW Azure tenancy \(completely separate from the internal MW Entra ID tenant \-\- public users are isolated from the corporate directory\)\. Register mobile app as a public client\. Define API scope, apply Melbourne Water branding to hosted sign\-in pages \(logo, colours, copy\)\. Configure MFA: Email OTP as second factor\. Validate all user flows end\-to\-end in dev tenant before mobile team integration begin\.

3

SQL Schema

No auth tables required\.   
Data schema: Permits, PermitApprovals \(full audit log\), Visits, BirdSightings, Content and others

3

Operations API

Permits Operator state transitions role\-gated to WTP\.Operator\. Visits, bird sightings, hazards, tours, and static content endpoints\. Swagger/OpenAPI spec published to APIM developer portal\.

18

APIM Configuration

Path routing Entra ID JWT validation \(internal tenant, WTP\.Operator role claim required\), rate limiting per operator\. Named Values configured as Key Vault references\. Backend configuration for both App Services\. OpenAPI specs imported for both APIs\.

3\.5

Entra ID 

Operator App Registration\. App registration in MW internal Entra ID tenant\. Define app roles: WTP\.Operator and WTP\.Admin\. Assign roles to Melbourne Water staff security groups\. Configure APIM Admin Product to validate against internal tenant issuer and audience\. Configure Operator Web App SPA redirect URIs\.

1

CI/CD Pipelines

IaC, Identity, Operations, Static Web App, Database across DevTest, UAT, Prod and DR\. All deployments use managed identity – no stored service principal secrets\.

3

Notification Hubs Integration

Configure Notification Hubs namespace and hub per environment\. Register APNs \(iOS\) and FCM \(Android\) credentials \(provided by mobile team\)\. Tag strategy: userId:\{n\} per registered user\. Operations API integration for operator\-triggered push dispatch\. Email fallback logic via Azure Communication Services for notifications unacknowledged after 24 hours\.

1\.5

Key Vault Configuration

Provision Key Vault per environment\. Secrets stored: JWT signing key \(HS256\), SQL connection strings, Azure Communication Services connection key, Notification Hubs connection string\. APIM Named Values configured to reference Key Vault secrets directly\. App Services configured with Key Vault references in app settings \(no plaintext secrets\)\. Managed identity RBAC configured with Key Vault Secrets User role for all consumers\.

1\.5

Security and Network Controls

Private endpoint for Azure SQL with no public network access\. VNet integration for both App Services to SQL\. App Service access restriction to APIM outbound IPs only \-\- no direct internet access to APIs\. TLS enforced on all endpoints\.

Included in IaC

Monitoring and Alerting

Application Insights connected to both APIs and APIM with distributed tracing\. Log Analytics Workspace as centralised log sink\. Alerts configured for: HTTP 5xx error spike\. 

1\.5

Integrating Testing with Mobile Team

Publish Swagger/OpenAPI specs to APIM developer portal\. Provide dev environment base URL and test credentials to mobile team\. Coordinate mobile team testing of all auth flows \(register, login, forgot\-password, token refresh, JWT attachment to API calls\)\. Bug fix cycle following initial integration\. 

3

Documentation and Handover

Architecture decision record for SQL Auth approach and documented migration path to Entra External ID\. API endpoint reference for internal teams\. CI/CD pipeline documentation\. 

3

__TOTAL__

__48\.5__

*\*Estimates can vary depending on additional integrations required*

