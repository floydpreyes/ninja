# Weekly Update – 12 June 2026

## SOC / Sentinel
- Continued development and testing of the new Snowflake Azure Function in the dev environment, progressing through iterative coding cycles covering log retrieval, state management, and DCR ingestion via the `sentinel_connector.py` and `exporter.py` modules.
- Validated end-to-end data flow in dev, confirming Snowflake audit and activity log events are ingested correctly into the target Sentinel DCR tables with the expected schema mapping.
- Raised change request CHG0058125 to govern the production deployment of the Snowflake ingestion function, including the new DCR tables and DCR schema required to support the pipeline.

## AIS
- Continued troubleshooting the ongoing connectivity and configuration issues affecting the APIM DevTest instance, investigating network-layer and subnet-related root causes.
- Identified redeployment to a different subnet as the next diagnostic step to isolate whether the issue is subnet-specific or related to the APIM instance configuration itself; redeployment to be scheduled pending team availability.

## Birdwatcher
- Met with representatives from the IDAM, Cybersecurity, and Wintel teams to discuss the requirements and prerequisites for enabling an External Microsoft Entra ID tenant within the MW environment.
- Progressed planning for the External Entra ID enablement, working on a formal change request and associated operational procedures to govern the deployment to the MW tenant in alignment with security and identity governance requirements.
