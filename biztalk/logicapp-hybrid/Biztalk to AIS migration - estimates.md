__BizTalk 2016 → Azure Integration Services migration for Melbourne Water__

__Specifications__

__Scope__

~55 in\-scope BizTalk integrations across 18 application groups

__Excluded__

13\-WaterWorks \(CGI\-managed\), 18\-BizTalk system apps \(decom only\), 20\-Flash Flood \(retire\)

__Approach__

3 waves: pattern templates → bulk migration → complex rewrites \+ decommission

__Platform__

Logic Apps Standard, APIM \(existing\), Service Bus Premium, Function Apps, Key Vault, Data Factory, Storage — built on MW’s existing AVM Bicep \+ CI/CD patterns

__Hard deadline__

BizTalk 2016 EOL Jan 2027 \(end of support\)

__Recommended start__

Mid\-2026

__Recommended team__

3 engineers — 1 Lead DevOps/Integration Engineer \(senior\) and 2 Integration Engineers \(mid\-level\)

__Team allocation__

- __Lead DevOps/Integration Engineer__ \(~45% of total effort, ~390 d\) — owns platform architecture and IaC, leads discovery and complexity classification, designs and builds all Wave 1 templates, leads Wave 3 very complex rewrites, drives cutover coordination across all waves, and owns architecture documentation and handover\. Requires strong Logic Apps Standard, Bicep, Service Bus, APIM, and \+5 years integration experience\.
- __Integration Engineer 1__ \(~30% of total effort, ~260 d\) — supports discovery, executes Wave 2 simple and standard migrations using Wave 1 templates, builds and maintains CI/CD pipelines, and runs integration and regression testing\. Mid\-level Azure DevOps and integration background\.
- __Integration Engineer 2__ \(~25% of total effort, ~220 d\) — supports discovery, executes Wave 2 complex migrations \(XSLT/Liquid transforms, on\-premises gateway, \+\.NET Function App ports\), supports Wave 3 rewrites, and leads BizTalk decommission activities\. Should have BizTalk or similar integration platform background\.  

Calendar estimate with 3 engineers \(start mid\-2026\): ~12 months engineering calendar → finish approximately __Jun 2027__\. Wave 2 is the primary parallelisation window; Wave 1 must complete before Wave 2 bulk work begins and Wave 3 runs in series at the end\. The 12\-month calendar reflects realistic availability \(leave, competing BAU priorities, onboarding ramp\-up for new engineers\) and is the recommended committed date to take to governance\.

__Background__

Melbourne Water operates approximately 55 BizTalk 2016 integrations across 18 application groups, connecting enterprise systems including TechOne, Pega, SAP, and a range of on\-premises and cloud\-hosted operational data sources\. BizTalk 2016 reaches end of support in January 2027, creating a hard deadline for migration to a modern, supportable platform\.

The target platform is Logic Apps Standard for orchestration, Azure API Management for inbound and outbound API governance, Service Bus Premium for reliable async messaging, Function Apps for custom transforms and adapters, and Azure Data Factory for bulk data movement\. All infrastructure is delivered as Bicep via Melbourne Water’s existing AVM patterns and Azure DevOps CI/CD pipelines\. Key Vault and managed identity are used throughout — no stored credentials\.

The migration is structured in three waves\. Wave 1 establishes reusable pattern templates and validates the approach with three pilot integrations\. Wave 2 executes the bulk of simple, standard, and complex migrations using those templates\. Wave 3 tackles very complex rewrites and decommissions the BizTalk environment\. Thirteen WaterWorks integrations \(CGI\-managed\), BizTalk system apps, and the Flash Flood integration are excluded from scope\.

__Scope of Works__

The scope of this project includes:

- __Discovery and Interface Analysis__ of all 55 in\-scope BizTalk integrations using aimbiztalk and BizTalk Documenter tooling to validate message schemas, maps, adapters, orchestrations, and receive/send port configurations\.
- __Pattern Classification__ of each integration into complexity buckets, with documented rationale and a migration approach per integration\.
- __Platform and Infrastructure Setup__ — Bicep modules for Logic Apps Standard, Service Bus Premium, APIM policy updates, Function Apps, Data Factory, Key Vault, and associated networking across Dev, Test, UAT, Production, and DR environments\.
- __Wave 1 — Pattern Templates and Pilot Migrations__ — build reusable Logic Apps and Function App templates for each complexity pattern and validate with three pilot integrations end\-to\-end, including cutover and parallel run\.
- __Wave 2 — Bulk Migration__ of simple, standard, and complex integrations using Wave 1 templates; includes per\-integration build, test, and cutover execution\.
- __Wave 3 — Very Complex Rewrites__ of the highest\-complexity integrations \(stateful orchestrations, custom adapters, multi\-system correlation\); includes extended parallel\-run periods\.
- __Cutover and Parallel\-Run Operations__ — coordinated cutover execution per integration, parallel monitoring windows, and rollback procedures\.
- __BizTalk Decommission__ — retire BizTalk applications, remove receive/send ports, and clean up on\-premises infrastructure following final cutover\.
- __CI/CD Pipelines__ for all Logic Apps, Function Apps, and Bicep infrastructure across all environments using managed identity — no stored service principal secrets\.
- __Validation and Testing__ including integration\-level smoke tests, end\-to\-end regression, and sign\-off from application owners\.
- __Knowledge Transfer and Documentation__ — runbooks, architecture decision records, and pipeline documentation for the AIS team\.

__Effort shown is DevOps engineering effort only__ — programme management overhead, CAB approval lead times, freeze periods, stakeholder scheduling, and external partner dependencies are out of scope and owned by the programme manager\. The PM should layer those on top of the engineering numbers below to produce a committed delivery date\.

The following table details the estimated engineering effort required for delivery\. Estimates assume three engineers — one Lead DevOps/Integration Engineer and two Integration Engineers — working in parallel across Wave 2\.

__CONSERVATIVE ESTIMATE__

__Name__

__Notes__

__Estimate \(Days\)__

Discovery and Interface Analysis

Run aimbiztalk and BizTalk Documenter across all 55 in\-scope integrations\. Validate message schemas, adapters, orchestrations, maps, and receive/send port configurations\. Classify each integration into a complexity bucket with documented rationale\. Produce interface register and migration approach per integration\.

60

Platform and Infrastructure Setup \(IaC\)

Provision Logic Apps Standard environments, Service Bus Premium namespaces, Function App hosting plans, Data Factory instances, Key Vault, Application Insights, and Log Analytics Workspace across Dev, Test, UAT, Production, and DR\. All resources as Bicep via Azure DevOps pipelines with managed identity\. Establish CI/CD pipeline skeletons for Logic App and Function App deployments\.

25

Wave 1 — Pattern Templates and Pilot Migrations

Build reusable Logic Apps and Function App templates for each complexity pattern \(file move, request\-response, transform\-heavy, stateful\)\. Validate templates against three representative pilot integrations end\-to\-end, including cutover, parallel\-run monitoring, and application owner sign\-off\. Templates form the build standard for all Wave 2 work\.

105

Wave 2 — Bulk Migration: Simple and Standard \(30 integrations\)

Migrate all simple and standard integrations using Wave 1 templates\. Includes per\-integration Logic Apps build or APIM policy configuration, schema and transform migration, unit and integration testing, cutover coordination, and short parallel\-run monitoring\. Allows for a proportion of integrations requiring deviation from the standard template\.

175

Wave 2 — Bulk Migration: Complex \(20 integrations\)

Migrate complex integrations requiring structural reshaping, XSLT or Liquid transforms, SOAP and on\-premises connectivity via on\-premises data gateway, or \.NET helper logic ported to Function Apps\. Includes more extensive unit testing, longer parallel\-run periods, and formal application owner sign\-off per integration\.

225

Wave 3 — Very Complex Rewrites \(5 integrations\)

Rewrite the highest\-complexity integrations — stateful orchestrations, multi\-system correlation, custom adapters, or integrations with no direct Logic Apps connector equivalent\. Includes significant design work, extended parallel\-run periods \(up to two weeks per integration\), and close coordination with application owners and vendor teams\.

90

Cutover and Extended Parallel\-Run Operations

Coordinated cutover execution across all waves\. Includes scheduling cutover windows with application owners, monitoring parallel\-run periods, incident triage and bug fix cycles, rollback execution where required, and final sign\-off\. Allows for complex integrations requiring extended monitoring beyond the standard one\-week window\.

95

BizTalk Decommission and Environment Cleanup

Retire all migrated BizTalk applications, remove receive/send ports and orchestrations, uninstall BizTalk bindings, and coordinate decommission of on\-premises BizTalk infrastructure with the infrastructure team\. Includes final validation that all integrations are live on the new platform before decommission proceeds\.

25

Escalation and Surprise Reserve

Buffer for late\-breaking discoveries: undocumented custom adapters, BAM surface area, EDI integrations not identified in discovery, extended parallel\-run requirements due to data quality issues, rework cycles following application owner testing, or delays caused by vendor\-side changes during cutover\.

70

__TOTAL__

__870__

*\*Estimates can vary depending on undiscovered integration complexity and organisational scheduling dependencies\.*
