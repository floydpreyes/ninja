__Statement of Work__

__MW Cost Centre No\. __

 

__Reference \# & __

__Date __

0888\-2026\-06\-002

01\-06\-2026

Name

BizTalk Migration Project\-Infra build for POC

This Statement of Work \(“__SOW__”\) is entered into between:

__TATA CONSULTANCY SERVICES LIMITED__ \(__TCS or SUPPLIER__\) \(ABN 28 109 981 777\) of Level 6, 76 Berry Street North Sydney NSW 2060

And

<a id="_Hlk514428056"></a>__Melbourne Water Corporation __\(ABN 81 945 386 953\) of 990 La Trobe Street, Docklands, Victoria, 3008 \(MW\)\.

This SOW describes the Services the Supplier will perform for MW\. This SOW is subject to the terms and conditions of the Information Technology Managed Services Agreement between MW and TCS dated 2nd August 2018\.  \(“__Agreement__”\)\.  This SOW is made under and forms part of the Agreement,and does not constitute a separate contractual relationship between the parties\.  

In accordance with clause 7 of the Agreement, MW requests the supply of certain Services and Deliverables, and the Supplier has agreed to provide those Services and Deliverables on the terms and conditions set out below\.  

On execution of this SOW: the terms of this SOW are incorporated into the Agreement as if fully set out in the text of the Agreement; and the parties must perform their obligations under this SOW on the terms of the Agreement, as included in the SOW\.  

__All capitalised terms have the meaning given in this SOW or the Agreement\.__

## __Services being provided under this SOW__

__The Supplier will provide the following Services under this SOW: 	__

__Background__

Melbourne Water is undertaking an initiative to modernize its integration platform\. As part of this effort, there is a need to evaluate Azure Logic Apps Standard in a hybrid deployment model to support integration between on\-premises systems and Azure services\. Currently, this capability has not been validated within the existing on\-premises environment\. To address this, a dedicated Linux virtual machine will be provisioned on\-premises to host a lightweight Kubernetes \(K3s\) cluster\. This environment will be connected to Azure using Azure Arc, enabling centralized management while retaining on\-premises deployment\. This setup will serve as a Proof of Concept \(POC\) to assess the feasibility, performance, and operational suitability of the proposed architecture before broader implementation across the Melbourne Water integration platform\.

## __Proposed Solution__

1. Scope of Work

           The scope of this project includes the following activities:

- Provision a single Linux virtual machine within the on\-premises dev environment with the required compute, storage, and network configurations\.
- Create firewall rules for DNS and domain communication
- Firewall port\-opening between 1 x new IT RHEL Linux server in DMZ and border firewall\.
-  Vulnerability scan and remediation for the newly built Dev server\(x1\)\-After server build and after                          application installation
- Onboard the admin account to CyberArk
- Troubleshooting the network connectivity from on prem to Azure arc
- Troubleshooting from the VM/infrastructure layer if required, to ensure successful setup and stability of      

   the environment\.

1. <a id="_Ref258494626"></a> Deliverables

The deliverables from TCS for this scope of work are:

- Scope mentioned in Section 2\.1

1. Exclusions

The exclusions for this scope of work will be:

- Application deployment, service activation, and handover activities are outside the scope of   the project\.
- Connectivity setup and validation between the on\-premises environment and Azure are outside the     scope of this project 

1. Assumptions

The assumptions for this scope of work will be:

- Melbourne Water should provide all the relevant information required for the TCS Project Manager to perform/deliver this SOW as agreed timeline\. 
- The required approvals for infrastructure build and access provisioning will be obtained prior to commencement\.
- Any advanced troubleshooting beyond the VM/infrastructure layer is out of scope; only basic VM\-level troubleshooting will be performed, if required
- All coordination with external vendors or third parties will be managed by Melbourne Water\.
- If there is any additional component/effort required, then it will be managed through a variation and implementation cost will require to be adjusted\.
- Connectivity setup and validation between the on\-premises environment and Azure are outside the     scope of this project and will be provisioned and verified by Melbourne Water prior to implementation\.
- Melbourne Water may terminate the Project at any time by giving TCS at least 20 Business Days’ notice in writing of such termination\. Any effort spent before the end date of the notice period should be paid in full \.
- Result in termination or de\-scoping, TCS will be entitled to charge Melbourne Water for any Project Service activity delivered in accordance with this Agreement and the Statement of Work prior to the effective date of the termination\.
- Timely approval will be provided by MW so as not to impact deliverables of the project\.
- All dependencies, constraints, risks, issues, or assumptions relevant to the delivery of this SOW have been noted in this document\. Any changes to these dependencies, constraints, risks , issues, or assumptions identified during the lifecycle of the project will be managed through the standard governance process\.

1. Acceptance Criteria

- Melbourne Water acceptance of the listed deliverables in section 2\.2 Deliverables

1. Dependencies

- Availability of on\-premises infrastructure \(compute, storage, and network\) for provisioning the Linux VM\.
- Melbourne Water to provide timely decision and approval for any requirements in this SOW\.
- Melbourne Water resource availability if/when project requires as per agreed project plan\.

1. Risks 

- NA\.

1.  Melbourne Water Inputs

- Provide relevant information to the project resources to perform their activities as mentioned in 2\.2 Deliverables above
- Timely response from Melbourne Water on decisions
- Any additional work /effort out of scope for this SOW will be submitted to MW for approval prior to undertaking the work
- Need to ensure third\-party vendor availability on time to ensure completion of the project within timeline\.

1. RACI Matrix

__Activity__

__MW__

__TCS__

Environment Build and configuration\(1xdev\)

A, C, I

R

Firewall rule creation and implementation\(x3\)

A, C, I

R

Service account creation

A, C, I

R

Troubleshooting from on prem network and VM layer

A, C, I

R

Vulnerability scan and remediation after the VM build and application installation  

A, C, I

R

R\-Responsible 

A\-Accountable 

C\-Consulted 

I\-Informed

1.  Service Location 

- Offshore, India 

## __Term__

- Fixed term SOW    This SOW commences on __09\-06\-2026__ and continues until __30\-06\-2026__\.  
- SOW without fixed term   This SOW commences on DD\-MMM\-YYYY and continues until DD\-MMM\-YY, or all the Services and Deliverables have been provided, unless terminated earlier under this SOW or the Agreement

## __Effort & Staffing \(resourcing requirements in Person Days\)__

- Not Applicable

## __Charges__

1. Time & Materials 

- Not Applicable

1. Fixed Price

                 The total fixed price of this SOW is __$6,454\.00 __excluding GST\.

 

1. Pass through Costs

- Not Applicable

1. Other Charges

- Not Applicable	

## __Payment Schedule: __

__Milestone Description__

__Amount in AUD__

__Amount in AUD__

__Amount in AUD__

__GST__

__Total__

__Milestone Date__

__\(Offshore Effort\) __

__\(Onsite Effort\) __

__\(Ex\.GST\) __

__\(10% on Onsite Cost\)__

__\(In\. GST\)__

Infra readiness: 1XVM build, vulnerability scan and remediation\(x2 times\);Firewall change implementation\(x3\);Prepare Build document ;Troubleshooting issues if required from network or VM end

$6,453\.46

 

$6,453\.46

 

$6,453\.46

   30\-Jun\-26

__Total__

__$6,453\.46__

 

__$6,453\.46__

 

## __Service Levels __

- Not Applicable

## __Service Credits and other consequences __

\.

- Not Applicable

## __Additional terms __

  
Please specify any additional terms, as agreed to by both parties, that are applicable for this SOW

\.

__Accepted by:__

__Accepted by:__

__Tata Consultancy Services Limited__

A\.B\.N\. 28 109 981 777

__Melbourne Water Corporation __

By:  \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_­­­ 

Authorised Signature

By:  \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

Authorised Signature

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

Name:

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  
Name:

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  
Title:

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  
Title:

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ 

Date:

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  
Date:

	

	

