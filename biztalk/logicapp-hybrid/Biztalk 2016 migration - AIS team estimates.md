__BizTalk 2016 migration – AIS team effort estimates__

__Specifications__

__Background__

Melbourne Water operates approximately 56 BizTalk 2016 integrations across 18 application groups, connecting enterprise systems including TechOne, Pega, SAP, and a range of on\-premises and cloud\-hosted operational data sources\. BizTalk 2016 reaches end of support in January 2027, creating a hard deadline for migration to a modern, supportable platform\.

The target platform is Logic Apps Standard for orchestration, Azure API Management for inbound and outbound API governance, Service Bus Premium for reliable async messaging, Function Apps for custom transforms and adapters, and Azure Data Factory for bulk data movement\. All infrastructure is delivered as Bicep via Melbourne Water’s existing AVM patterns and Azure DevOps CI/CD pipelines\. Key Vault and managed identity are used throughout — no stored credentials\.

The migration is structured in three waves\. Wave 1 establishes reusable pattern templates and validates the approach with three pilot integrations\. Wave 2 executes the bulk of simple, standard, and complex migrations using those templates\. Wave 3 tackles very complex rewrites and decommissions the BizTalk environment\. 

__Scope of Works__

The scope of this project includes:

- __Discovery and Interface Analysis__ of all 56 in\-scope BizTalk integrations using analysis from existing BizTalk SMEs in conjunction with running BizTalk Documenter tooling to validate message schemas, maps, adapters, orchestrations, and receive/send port configurations\.
- __Pattern Classification__ of each integration into complexity buckets, with documented rationale and a migration approach per integration\.
- __Platform and Infrastructure Setup__ — Bicep modules for Logic Apps Standard, Service Bus Premium, APIM policy updates, Function Apps, Data Factory, Key Vault, and associated networking across Dev, UAT, Production, and DR environments\. Additional time included for setting up hybrd Azure ARC infrastructure for on\-prem to on\-prem workloads\.
- __Wave 1 — Pattern Templates and Pilot Migrations__ — build reusable Logic Apps and Function App templates for each complexity pattern and validate with three pilot integrations end\-to\-end, including cutover and parallel run\.
- __Wave 2 — Bulk Migration__ of simple, standard, and complex integrations using Wave 1 templates; includes per\-integration build, test, and cutover execution\.
- __Wave 3 — Very Complex Rewrites__ of the highest\-complexity integrations \(stateful orchestrations, custom adapters, multi\-system correlation\); includes extended parallel\-run periods\.
- __Cutover and Parallel\-Run Operations__ — coordinated cutover execution per integration, parallel monitoring windows, and rollback procedures\.
- __BizTalk Decommission__ — retire BizTalk applications, remove receive/send ports, and clean up on\-premises infrastructure following final cutover\.
- __CI/CD Pipelines__ for all Logic Apps, Function Apps, and Bicep infrastructure across all environments using managed identity — no stored service principal secrets\.
- __Validation and Testing__ including integration\-level smoke tests, end\-to\-end regression, and sign\-off from application owners\.
- __Knowledge Transfer and Documentation__ — runbooks, architecture decision records, and pipeline documentation for the AIS team\.

  
The following table details the estimated engineering effort required for delivery\. 

__Name__

__Notes__

__Estimate \(Days\)__

Discovery and Interface Analysis

Detailed analysis of artifacts handed over from TCS BizTalk SMEs and validate with biztalk documenter tool\. Produce interface register and migration approach per integration\.

15

Platform and Infrastructure Setup \(IaC\)

Provision required Azure resources both cloud / hybrid \(Azure Arc for on\-prem sensitive workloads\) \. All resources as Bicep via Azure DevOps pipelines with managed identity\. Establish CI/CD pipeline skeletons across all environments, dev, uat, production and dr\. 

45

Wave 1 – Pattern templates and pilot migrations

Build reusable Logic Apps and Function App templates for each complexity pattern \(file move, request\-response, transform\-heavy, stateful\)\. Validate templates against three representative pilot integrations end\-to\-end, including cutover, parallel\-run monitoring, and application owner sign\-off\. Templates form the build standard for all Wave 2 work\.

105

Wave 2 – Bulk Migration: Simple and Standard

Migrate complex integrations requiring structural reshaping, XSLT or Liquid transforms, SOAP and on\-premises connectivity via on\-premises data gateway, or \.NET helper logic ported to Function Apps\. Includes more extensive unit testing, longer parallel\-run periods, and formal application owner sign\-off per integration\.

175

Wave 2: Bulk Migration: Complex

Path routing Entra ID JWT validation \(internal tenant, WTP\.Operator role claim required\), rate limiting per operator\. Named Values configured as Key Vault references\. Backend configuration for both App Services\. OpenAPI specs imported for both APIs\.

225

Wave 3: Very Complex Rewrites 

Rewrite the highest\-complexity integrations — stateful orchestrations, multi\-system correlation, custom adapters, or integrations with no direct Logic Apps connector equivalent\. Includes significant design work, extended parallel\-run periods \(up to two weeks per integration\), and close coordination with application owners and vendor teams\.

90

Cutover and Extended Parallel\-Run Operations

Coordinated cutover execution across all waves\. Includes scheduling cutover windows with application owners, monitoring parallel\-run periods, incident triage and bug fix cycles, rollback execution where required, and final sign\-off\. Allows for complex integrations requiring extended monitoring beyond the standard one\-week window\.

95

Escalation and Surprise Reserve

Buffer for late\-breaking discoveries: undocumented custom adapters, BAM surface area, EDI integrations not identified in discovery, extended parallel\-run requirements due to data quality issues, rework cycles following application owner testing, or delays caused by vendor\-side changes during cutover\.

70

Security and Network Controls

Private endpoints for Azure resources with no public network access\. VNet integration for both all Serverless Apps\. Managed identities enforced on all azure resources and Azure RBAC least privilege access followed\. 

Included in IaC

Monitoring and Alerting

Application Insights connected to all serverless apps and APIM with distributed tracing\. Log Analytics Workspace as centralised log sink\. Alerts configured for: HTTP 5xx error spike\. Alerts fine tuning after several days of monitoring\.

15

Documentation and Handover

Low\-level design and as\-built documentation and handover to BAU operations team\.  

10

__Total__

__845__

__Recommended team__

3 engineers — 1 Lead DevOps/Integration Engineer and 2 Integration Engineers

__Team allocation__

- __Lead DevOps/Integration Engineer__ \(~45% of total effort, ~375 d\) — owns platform architecture and IaC, leads discovery and complexity classification, designs and builds all Wave 1 templates, leads Wave 3 very complex rewrites, drives cutover coordination across all waves, and owns architecture documentation and handover\. 
- __DevOps/Integration Engineer 1__ \(~30% of total effort, ~260 d\) — supports discovery, executes Wave 2 simple and standard migrations using Wave 1 templates, builds and maintains CI/CD pipelines, and runs integration and regression testing\. 
- __DevOps/Integration Engineer 2__ \(~25% of total effort, ~220 d\) — supports discovery, executes Wave 2 complex migrations \(XSLT/Liquid transforms, on\-premises gateway, \+\.NET Function App ports\), supports Wave 3 rewrites, and leads BizTalk decommission activities\. 

Calendar estimate with 3 engineers \(start mid\-2026\): ~12 months engineering calendar → finish approximately __Jun 2027__\. Wave 2 is the primary parallelisation window; Wave 1 must complete before Wave 2 bulk work begins and Wave 3 runs in series at the end\. The 12\-month calendar reflects realistic availability \(leave, competing BAU priorities, onboarding ramp\-up for new engineers\) and is the recommended committed date to take to governance\.

