IT Disaster Recovery Test Plan AIS Services 

Plan

January 2026

<a id="_Toc512348204"></a>Table of contents

[1\.	Purpose	3](#_Toc200521421)

[2\.	Testing Overview	3](#_Toc200521422)

[2\.1	Test Objectives	3](#_Toc200521423)

[2\.2	System Architecture	4](#_Toc200521424)

[3\.	Scope	4](#_Toc200521425)

[3\.1	In Scope	4](#_Toc200521426)

[3\.2	Out of Scope	5](#_Toc200521427)

[4\.	Test Scenario and Calendar	5](#_Toc200521428)

[5\.	Test Strategy	6](#_Toc200521429)

[5\.1	Test Environment	6](#_Toc200521430)

[5\.1\.1	Physical Test Environment Architecture	6](#_Toc200521431)

[5\.1\.2	Test Data Requirements	6](#_Toc200521432)

[5\.2	Test Dependencies & Assumptions	6](#_Toc200521433)

[5\.3	Risk Management	6](#_Toc200521434)

[5\.4	IT DR Runsheet	7](#_Toc200521435)

[6\.	Administration and Logistics	7](#_Toc200521436)

[6\.1	Test Team Responsibilities	7](#_Toc200521437)

[6\.2	Support Requirements	7](#_Toc200521438)

[6\.3	Change Procedure	8](#_Toc200521439)

[6\.4	Reporting	8](#_Toc200521440)

[6\.5	Links to Documentation	9](#_Toc200521441)

[7\.	Document History 	9](#_Toc200521442)

<a id="_AbbreviationsMarker"></a>

<a id="_Toc200521421"></a># Purpose

<a id="_Toc519767701"></a><a id="_Toc512348205"></a><a id="_Toc511213798"></a>This document captures the Disaster Recovery Test Plan for the ongoing assurance of the Melbourne Water Tier 1 and Tier 2 IT services\. Test Planning is critical to ensuring the successful outcome of testing activities\. This document will provide answers to questions such as:

•	What will be tested?

•	Who will perform the testing?

•	When will the testing be conducted?

•	How will the testing be performed?

•	How will we know when testing is complete?

•	What must be produced by the testing?

*Control Objective:*

*a\. Test the contingency plan for the system according to the activity schedule using the following testing approach to determine the effectiveness of the plan and the readiness to execute the plan: as per test types\. *

*b\. Review the contingency plan test results; and *

*c\. Initiate corrective actions, if needed\. 	*

NIST800\.53r5 control CP\-4

# <a id="_Toc166500283"></a><a id="_Toc200521422"></a>Testing Overview 

## <a id="_Toc166057887"></a><a id="_Toc166500284"></a><a id="_Toc200521423"></a><a id="_Toc511631812"></a>Test Objectives 

The main objectives of this document is to outline the DR approach and scope per IT service\. To do so, Testing Schedule, confirmtion that the Disaster Recovery Plan is current as well as achievability of the Recovery Point and Recovery Time Objectives will be understood prior to testing\.

The current  Disaster Recovery Plan for AIS Services can be found here:  

[EMRG PLA Disaster Recovery \- Azure Integration Services](https://inflo.mwc.melbournewater.com.au/inflo/cs.exe/properties/70970721)

The objectives of the test are to:

- Verify that in the event of a loss of the AIS Services the disaster recovery plan contains accurate and necessary information and the required tasks to recover the system at an alternative location;
- Confirm that the recovered AIS Services can be restored to a business accepted state;
- Check that the Disaster Recovery procedure is well understood and known by all necessary personnel\.
- Check that all necessary resources are available to complete the recovery processes within the Recovery Time Objective\.
- Validate roles, contact details and assignment of tasks;
- Validate the plan’s recovery certificate; and
- Identify any issues with the recovery process and plans, and if necessary, recommend actions to resolve issues\.

## <a id="_Toc166054578"></a><a id="_Toc166500285"></a><a id="_Toc200521424"></a>System Architecture

The System Architecture diagram detailing the production and test environment for this IT service can be referenced in the AIS Services IT DR Plan, link provided in section 6\.5 Links to Documentation\. The system architecture should represent the complete intended system architecture deployed into the production environment\. This may differ from the test environment covered later in this document\.

<a id="_Toc200521425"></a># Scope

## <a id="_Toc166054580"></a><a id="_Toc166500287"></a><a id="_Toc200521426"></a>In Scope

This section identifies one or many systems or system components that are included as in scope for this test plan\. The “Functionality / Processes to be tested” column should provide a brief description of the critical business functionality that will be tested within each system\.

The following table includes systems, functionality or processes that are in scope of testing\. 

__System \(Cloud Resource Name\)__

__Functionality / Process Impacted__

evhns\-prd\-ae\-ais

Event Hubs Namespace

func\-prd\-ae\-ais

Function App

func\-prd\-ae\-ais\-asp

App Service plan

logic\-prd\-ae\-ais

Logic App \(Standard\)

logic\-prd\-ae\-ais\-asp

App Service plan

stprdaeaisapp

Storage account

apim\-prd\-ase\-ais

API Management

adf\-prd\-ae\-ais

Azure Data Factory

evgt\-prd\-ase\-ais

Event Grid

kv\-prd\-ase\-ais

Key Vault

sbns\-prd\-ase\-ais

Service Bus

stprdaseais

Storage Account \(Business\)

logic\-prd\-ae\-ecloud

Logic App Standard \(eCloud\)

logic\-prd\-ae\-empro

Logic App Standard \(empro\)

logic\-prd\-ae\-nabfp

Logic App Standard \(nabfp\)

logic\-prd\-ae\-vago

Logic App Standard \(vago\)

logic\-prd\-ae\-westpac

Logic App Standard \(westpac\)

logic\-prd\-ae\-sentinel

Logic App Standard \(sentinel\)

logic\-prd\-ae\-pega

Logic App Standard \(pega\)

logic\-prd\-ae\-pol

Logic App Standard \(Altus POL\)

func\-prd\-ae\-pol

Function App \(Altus POL\)

stprdaset1bus

Storage account \(Business\)

stprdaset1extsftp

Storage Account \(sftp\)

stprdaet1logic

Storage Account \(Logic Apps\)

stprdasepega

Storage Account \(Pega\)

stprdasepol

Storage Account \(Altus POL\)

kv\-prd\-ase\-t1

Key Vault \(TechOne\)

kv\-prd\-ase\-pol

Key Vault \(Altus Pol\)

kv\-prd\-ase\-pega

Key Vault \(Pega\)

## <a id="_Toc166054581"></a><a id="_Toc166500288"></a><a id="_Toc200521427"></a>Out of Scope

The systems and processes listed in this section should include all relevant systems and processes that have been excluded from testing scope\.

__System__

__Functionality / Process Impacted__

External third\-party systems

Connection from Westpac, Visa, VAGO, eCloud, ExpenseMe Pro

On\-premises systems

Connectivity from Melbourne Water premises

# <a id="_Toc166500289"></a><a id="_Toc200521428"></a>Test Scenario and Calendar

*IT Test Schedule dates are centrally managed by the Disaster Recovery & Business Continuity Lead and available *[*here*](http://inflo/inflo/cs.exe/properties/67783951) \. * The detail of the three regular test scenarios for your IT service are outlined below\.*

__Tabletop/ Simulation Test \(TT\):__

This scenario is a simulation test which allows the teams to collaboratively run through various scenarios and detail how they would respond under various scenarios or circumstances, this can help verify preparedness and understanding of teams responses to DR triggers and events  

__Isolation/ QFDR Test \(IT\):__

For this scenario an isolated failover or ‘copy’ of the production environment is created in an isolated environment for testing purposes\. This allows the team to verify the availability and integrity of the systems in a controlled way with little to no production impact\.  
  
__Physical Test \(PT\)__: 

For this scenario a replication of a total loss of site is used\. Failure scenarios where this would be applicable include complete power failure of the site, severe damage or hazard at the site\.  


# <a id="_Toc166500290"></a><a id="_Toc200521429"></a>Test Strategy 

## <a id="_Toc166054587"></a><a id="_Toc166500291"></a><a id="_Toc200521430"></a>Test Environment<a id="_Toc166054588"></a>

### <a id="_Toc166500292"></a><a id="_Toc200521431"></a>Physical Test Environment Architecture

If known, include details of the test environment configuration items in this section\. 

### <a id="_Toc166054589"></a><a id="_Toc166500293"></a><a id="_Toc200521432"></a>Test Data Requirements

Define any test data requirements\.

__System__

__Data Description__

__Data used for__

N/A

## <a id="_Toc166500294"></a><a id="_Toc200521433"></a>Test Dependencies & Assumptions

A dependency is something testing relies on and will impact testing if it’s changed or removed\. 

Assumptions are made when you do not have all the facts or possible outcomes needed to complete a plan\.

Type 

Dependency

Assumptions

Resourcing

Service recovery

Support personnel from NCS Cloud Operations team would be available to perform the Runsheet steps pertaining to AIS service recovery\.

Cloud Service Reliability

Cloud Infrastructure

Azure services in\-scope have been replicating successfully and will failover automatically as expected\.

<a id="_Toc166054591"></a>

## <a id="_Toc166500295"></a><a id="_Toc200521434"></a>Risk Management

Document all testing risks in this section\. A testing risk is any event that has not occurred yet but may occur, and if materialised would impact the planned scope, quality or objectives of the test\. Testing risks should also include the risk of any of the dependencies not being available\.

__Identified Risk__

__Risk Impacts__

__Countermeasure__

N/A

## <a id="_Toc200521435"></a>IT DR Runsheet

The link below is to the IT PLA DR Runsheet \- IT TEM DR Runsheet \- AIS Services\.xlsx, that is to be used for both planning, testing and actual DR mode\.

[IT PLA DR Runsheet \- Azure Integration Services](https://inflo.mwc.melbournewater.com.au/inflo/cs.exe/properties/70970429)

# <a id="_Toc166500302"></a><a id="_Toc200521436"></a>Administration and Logistics 

## <a id="_Toc511631826"></a><a id="_Toc166054604"></a><a id="_Toc166500303"></a><a id="_Toc200521437"></a>Test Team Responsibilities

List of the roles required for an IT DR exercise\. 

Role

Name

Responsibilities

Technical Recovery Lead

Dennis Singh

Network and Telephony Lead

0394735312

Dennis\.Singh@melbournewater\.com\.au

- Orchestrate the invocation of DR and recovery efforts for the affected service

System Owner

Michael Murray

Infrastructure Manager

0492996045

Michael\.Murray@melbournewater\.com\.au

- Provide SME support for the affected service\.

Applications  
Service Owner

Nick Brown

Applications Manager

0410334377 Nick\.Brown@melbournewater\.com\.au

- Facilitates all T1 applications DR activity

Altus POL

Service Owner

Neethu Manikyam  
neethu\.manikyam@melbournewater\.com\.au

- Service owner for Project Online

Service Owner

Dudley Ardona

Cloud Services and Hosting Lead

0413712067

Dudley\.Ardona@melbournewater\.com\.au

- Liaise with DR team to recover affected services within RTO\.

IT Services Provider

Cloud Operations \(NCS\)

IT\.CloudOps@melbournewater\.com\.au

- Deliver contracted services to support the recovery of services as per the agreed SLA's\.

Support

Cloud Operations \(AIS\)

[Floyd\.Reyes@melbournewater\.com\.au](mailto:Floyd.Reyes@melbournewater.com.au)  
[Ramya\.Thankappan@melbournewater\.com\.au](mailto:Ramya.Thankappan@melbournewater.com.au)  


- All AIS service recovery activities
- Support post\-test activities\. 

<a id="_Toc511631828"></a>

## <a id="_Toc166054605"></a><a id="_Toc166500304"></a><a id="_Toc200521438"></a>Support Requirements

This section must provide details of all areas that the test team require support from during this execution phase\. This should include, as an example, support from vendor build / development teams, test environment support and any business SME’s, etc\. Dates and times the support is required must also be included as support for specific systems may not be required throughout the entire test execution cycle\. You should also be specific on the hours the support is required or agreed, for example: Mon – Fri 9am to 5pm AEST\.

The table below details all support requirements for the test execution phase, including build teams, vendor support, environment support and business resources\.

__Area / System__

__Support Required__

__Date / Times Required__

Cloud Operations

Recovery of  Azure Integration services including all troubleshooting and PVT

Monday – Friday 9am\-5pm

Applications

Recovery and testing of Applications and workflows

Monday – Friday 9am\-5pm

External Integrations

Testing external connectivity for third\-party AIS integrations

Monday – Friday 9am\-5pm

## <a id="_Toc166054606"></a><a id="_Toc166500305"></a><a id="_Toc200521439"></a>Change Procedure

Changes to the approved plan are to be reviewed and approved by the System Owner\. 

- N/A for tabletop testing

## <a id="_Toc511631829"></a><a id="_Toc166054607"></a><a id="_Toc166500306"></a><a id="_Toc200521440"></a>Reporting

1. Conduct post\-test review\.
2. Compile test results\.
3. Prepare recommendations\.
4. Present findings; review and approve recommendations

Please provide email Confirmation from System Owner or Service Owner to the DR Management Team\.

## <a id="_Toc511631831"></a><a id="_Toc166054609"></a><a id="_Toc166500308"></a><a id="_Ref167703810"></a><a id="_Ref167703827"></a><a id="_Toc200521441"></a>Links to Documentation

Links to Documentation

Document

Info reference

AIS Services DR Plan

[EMRG PLA Disaster Recovery \- Azure Integration Services](https://inflo.mwc.melbournewater.com.au/inflo/cs.exe/properties/70970721)

AIS DR Runsheet

[IT PLA DR Runsheet \- Azure Integration Services](https://inflo.mwc.melbournewater.com.au/inflo/cs.exe/properties/70970429)

# Document History 

<a id="_VersionTableMarker"></a>Date

Reviewed/

Actioned By

Version

Action

January 2026

Floyd Reyes

Azure DevOps Engineer

2

Updated with downstream application consuming AIS services

June 2025

Braden Fraser

Cloud Consultant \(NCS\)

1

Create initial document

