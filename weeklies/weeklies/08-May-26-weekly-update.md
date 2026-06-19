# Weekly Update – [Your Name] – Week Ending 8 May 2026

## Altus Project Online
- Investigated and resolved an issue with the Altus .NET function app failing to reach the ESRI spatial services endpoint. The root cause was traced to an Entrust intermediate certificate that is no longer included in the default trust store for Azure-hosted .NET workloads following Microsoft's distrust of Entrust CAs. Remediated by explicitly importing the required Entrust certificate chain into the function app's trusted certificate store and validating the TLS handshake against the ESRI endpoint.
- Assisted the Altus team with production integration testing and validation post-fix, confirming end-to-end connectivity to ESRI services and verifying that dependent map and spatial data features were operating correctly in the production environment.

## SOC / Sentinel
- With the IT DR change freeze now lifted, raised the following change requests to progress outstanding Sentinel work:
  - **CHG0057605 – Grant Managed Identity / Service Principal RBAC Role to a Resource Group / Resources** *(Standard)*: Raised to assign the appropriate RBAC roles to the Sentinel-managed identities and service principals so they can access the necessary resource groups and individual resources. This underpins several ingestion pipelines and automation runbooks that were blocked pending correct identity permissions.
  - **CHG0057608 – Sentinel: Update Cloudflare R2 Bucket IP Restriction**: Raised to whitelist the confirmed egress IP address on the Cloudflare R2 bucket, unblocking the Cloudflare log ingestion function. This follows the prior week's work where the egress IP was identified in collaboration with the on-premises network team and confirmed with Cloudflare support.
  - **CHG0057553 – Sentinel: Firewall Rules Update for Audit Ingestion Sources**: Re-raised following the DR change freeze to apply the required firewall rule additions that permit inbound log streams from the remaining audit ingestion sources (Airlock and Cisco Umbrella). These rules had been authored and reviewed prior to the freeze and are ready for implementation.

## BizTalk / AIS Migration
- Commenced initial effort estimation for the migration of existing BizTalk orchestrations and pipelines to Azure Integration Services (AIS). Activities included reviewing the current BizTalk artefact inventory (orchestrations, schemas, maps, send/receive ports, and adapters), identifying analogous AIS components (Logic Apps, Service Bus, APIM, and Event Grid), and flagging areas of complexity such as custom pipeline components and legacy adapter dependencies. A structured effort estimate will be produced to inform project planning and resourcing conversations.

## Birdwatcher
- Attended a follow-up call with the Birdwatcher delivery and architecture teams to discuss the nature and scope of AIS team engagement required for the solution design and implementation phases. Key discussion points included integration pattern alignment, responsibilities across the delivery and AIS teams, and the approach to solution architecture documentation. Actions and engagement model to be formalised in the coming week.

## Next Week
- Monitor approval and coordinate implementation of CHG0057605, CHG0057608, and CHG0057553.
- Progress Altus production validation and address any further integration findings raised during PVT.
- Finalise the BizTalk-to-AIS effort estimate and present findings to project stakeholders.
- Formalise the AIS engagement model for Birdwatcher and begin initial design activities.
