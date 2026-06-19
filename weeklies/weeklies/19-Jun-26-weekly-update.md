# Weekly Update – 19 June 2026

## SOC / Sentinel
- Completed the production deployment of the Snowflake Azure Function and validated successful ingestion, confirming that the required audit and activity log tables are visible and populated within both Log Analytics and the Microsoft Sentinel platform.
- Commenced investigation into Azure Policy options for Linux VM onboarding, exploring approaches to automate the assignment of Azure VMs and Arc-connected Linux VMs to the DCR Linux Syslog data collection rule, reducing the need for manual association at scale.
- Authored a Standard Operating Procedure (SOP) for the renewal of API keys used by Sentinel ingestion pipelines, documenting the end-to-end process to support operational handover and ongoing maintenance.

## Birdwatcher
- Drafted the change request for the External Microsoft Entra ID enablement ahead of the planned 1 July implementation, coordinating with the broader technical team to align on prerequisites, dependencies, and approvals required for the go-live window.
- Commenced planning for the provisioning of development infrastructure to support Birdwatcher delivery, identifying resource requirements and environment configuration needed to stand up a functional dev environment.
- Reviewed the Operations API requirements and engaged with Colin to progress design alignment, working through open questions on endpoint structure, data contracts, and integration patterns.

## BizTalk
- Revised effort estimates for cloud-to-cloud integration patterns, incorporating updated scope and complexity assessments to reflect the current understanding of the migration requirements.
