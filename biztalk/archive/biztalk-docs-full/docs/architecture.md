# Architecture Context (Full Extract)

## Current BizTalk Role
BizTalk integrates across:
- GIS
- TechOne
- Maximo
- Chris21
- Kronos
- Project Online
- EnviroSys
- Zycus
- Pega
- PageUp
- WaterWorks
- IDAM
- IRIS
- Inflo

## Networking Flow
- Cloudflare (WAF + DNS)
- Border firewall (Palo Alto)
- DMZ
- ExpressRoute
- Azure tenancy (restricted internet access)

## Key Constraint
- All ingress/egress routed via on-prem perimeter

## Future Requirement
- Cloud security perimeter required for AIS-native integration
