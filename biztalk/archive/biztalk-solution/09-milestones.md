# BizTalk 2016 Migration — Project Milestones

**Client:** Melbourne Water  
**Project Start:** Mid-2026  
**Target Completion:** June 2027  
**Hard Deadline:** January 2027 (BizTalk 2016 end of support — all production traffic must be off BizTalk by this date)  
**Team:** 1 Lead DevOps/Integration Engineer + 2 Integration Engineers  

---

## Milestone Summary

| # | Milestone | Target Date | Effort Gate |
|---|---|---|---|
| M1 | Foundation Ready | Month 1 (Jul 2026) | 60 days |
| M2 | Wave 1 Complete — Pattern Templates Proven | Month 3 (Sep 2026) | 105 days |
| M3 | Wave 2a Complete — Simple & Standard Integrations | Month 7 (Jan 2027) | 175 days |
| M4 | Wave 2b Complete — Complex Integrations | Month 9 (Mar 2027) | 225 days |
| M5 | Wave 3 Complete — All Rewrites Done, Nothing on BizTalk | Month 11 (May 2027) | 90 days + Cutover |
| M6 | BizTalk Decommissioned, Project Closed | Month 12 (Jun 2027) | Handover + Monitoring |

---

## M1 — Foundation Ready
**Target: July 2026**  
**"We can build anything"**

### What is delivered
- Discovery complete: all 56 integrations analysed, classified by complexity, and assigned a migration approach
- Interface register published with rationale per integration
- All Azure infrastructure provisioned across Dev, UAT, Production, and DR environments:
  - Logic Apps Standard
  - Service Bus Premium
  - Azure API Management
  - Function Apps
  - Azure Data Factory
  - Key Vault + Managed Identity
  - Azure ARC (for on-premises sensitive workloads)
- CI/CD pipeline skeletons live in Azure DevOps across all environments
- No integrations migrated yet — the build platform is fully operational and the team can begin Wave 1

### Exit criteria
- [ ] Interface register reviewed and signed off by AIS Lead
- [ ] All Azure resources deployed and accessible
- [ ] CI/CD pipelines execute successfully for a smoke-test deployment
- [ ] Discovery outputs handed over from TCS BizTalk SMEs and validated

---

## M2 — Wave 1 Complete: Pattern Templates Proven
**Target: September 2026**  
**"Every pattern is proven — the build standard for Wave 2 is locked"**

### What is delivered
Three pilot integrations live in production on Logic Apps, each proving a reusable pattern:

| Pilot | Integration | Pattern Proven |
|---|---|---|
| 1 | `MW.Mobility.Maximo.Attachment` | On-prem ↔ on-prem API via Logic App + on-prem data gateway |
| 2 | `MW.DSSCon.PegaESRIIntegration.DrainageInfo` | HYBRID rewrite — Pega → ESRI, port BizTalk orchestration to .NET Function + Logic App |
| 3 | `MW.AMIS.Q4` | Scheduled file-pickup batch via Storage Blob trigger → Logic App |

- Reusable Logic App and Function App templates published per pattern
- APIM API + product templates documented
- Per-pattern cutover runbooks written and tested
- Application Insights alert baseline established (parity with BizTalk360)

### Exit criteria
- [ ] All three pilots running in production with application owner sign-off
- [ ] Templates reviewed and accepted as Wave 2 build standard by AIS Lead
- [ ] Cutover runbooks reviewed and approved
- [ ] **Go/No-Go decision for Wave 2 made** — this is the primary gate before bulk migration begins

> **Note:** This milestone is the highest-risk gate. The HYBRID rewrite pilot (DrainageInfo) validates the most expensive pattern in the programme. If this slips, Wave 3 estimates may need revision.

---

## M3 — Wave 2a Complete: Simple & Standard Integrations Migrated
**Target: January 2027**  
**"The bulk of the estate is on Azure"**

### What is delivered
All simple and standard BizTalk integrations migrated to Logic Apps Standard using Wave 1 templates. Integrations include (sequenced low-risk first, owner-batched):

- PageUp-Chris21 + IRIS (Terena Barnes owner group)
- Liquid-EnviroSys
- Project Online (3 interfaces)
- AMIS remainder
- Procurement (6 interfaces — Maximo)
- Zycus (6 interfaces — Vimmi Grover)
- Incentive batch shapes (5 interfaces)
- Kronos-Maximo
- SmartRain (2 interfaces)

Per integration: template clone → connector config → transform port → parallel run (1–2 weeks) → APIM backend swap → alert parity → BizTalk app in 30-day decom holding.

### Exit criteria
- [ ] All simple/standard integrations passing smoke tests in production
- [ ] Application owner sign-off obtained per integration
- [ ] BizTalk applications for completed integrations in 30-day decom holding period
- [ ] **All production traffic off BizTalk for these integration groups by end of January 2027** (end-of-support date)

> **Note:** This milestone aligns with the January 2027 BizTalk end-of-support hard deadline. Simple and standard integrations must be off BizTalk by this date.

---

## M4 — Wave 2b Complete: Complex Integrations Migrated
**Target: March 2027**  
**"All CAPEX-class integrations are on Azure"**

### What is delivered
All complex integrations migrated, including those requiring:
- XSLT or Liquid transforms
- SOAP and on-premises connectivity via on-premises data gateway
- .NET helper logic ported to Azure Function Apps
- Entra ID JWT validation and APIM policy configuration

Per integration: more extensive unit testing, longer parallel-run periods, formal application owner sign-off.

- Monitoring and alerting tuned (Application Insights, Log Analytics, alert fine-tuning after steady-state)
- BizTalk applications for completed integrations decommissioned (30-day holding period elapsed)

### Exit criteria
- [ ] All complex integrations passing end-to-end regression in production
- [ ] Application owner sign-off obtained per integration
- [ ] BizTalk applications decommissioned for all Wave 2 integrations
- [ ] Alert baselines reviewed and tuned

---

## M5 — Wave 3 Complete: All Integrations Migrated, Nothing on BizTalk
**Target: May 2027**  
**"BizTalk carries zero production traffic"**

### What is delivered
Full rewrites of the highest-complexity integrations — stateful orchestrations, multi-system correlation, and custom adapters — across three parallel streams:

| Stream | Integration Groups | Complexity |
|---|---|---|
| A — Pega/ESRI | DevConnect remainder (~12 APIs), CAD (2), Chris21 Enterprise Services | Stateful orchestration rewrite |
| B — Finance One ↔ Maximo | DFWS (6 API rewrites) | Multi-system correlation |
| C — IDAM/Chris21 | IDAM Chris21 Common, IDAM Chris21 Integration | Custom adapter replacement |

Per integration: shadow traffic (2 weeks) → byte-comparison reconciliation → phased traffic split (10% → 50% → 100%) over 1 week → full cutover.

Cutover and parallel-run operations for all waves complete, including:
- Incident triage and bug fix cycles
- Rollback execution where required
- Final sign-off from all application owners

### Exit criteria
- [ ] All 56 integrations live on Logic Apps Standard
- [ ] Zero active BizTalk receive/send ports carrying production traffic
- [ ] All extended parallel runs closed
- [ ] Application owner sign-off for all Wave 3 integrations

---

## M6 — BizTalk Decommissioned, Project Closed
**Target: June 2027**  
**"The BizTalk estate is gone"**

### What is delivered
- All BizTalk applications retired and removed
- On-premises BizTalk server decommission:
  - SVBTSPROD01–04 (BizTalk core servers)
  - SVBTSPROD05 (BizTalk360)
  - SVBZWEBPROD01/02 (WCF Routers)
- Network rule cleanup: DMZ, NetScaler, internal firewall rules removed
- CMDB updated
- Low-level design and as-built documentation complete
- Operations runbooks handed over to BAU team
- Architecture decision records published
- Lessons-learned session conducted

### Exit criteria
- [ ] All BizTalk servers decommissioned and confirmed offline
- [ ] Network rules cleaned up and confirmed by network team
- [ ] CMDB updated
- [ ] Documentation reviewed and accepted by BAU operations team
- [ ] Final lessons-learned session conducted
- [ ] Project formally closed

---

## Key Risks and Scheduling Notes

| Risk | Affected Milestone | Mitigation |
|---|---|---|
| Azure ARC / hybrid connectivity complexity | M1 | Prioritise ARC setup early; engage MW networking team in week 1 |
| HYBRID rewrite pilot slipping (DrainageInfo) | M2 | Treat as highest-priority Wave 1 item; Lead Engineer owns this directly |
| Application owner availability during bulk migration | M3–M4 | Batch integrations by owner; schedule sign-off windows 2 weeks ahead |
| Undocumented custom adapters or BAM surface area discovered late | M5 | 70-day escalation reserve budgeted for rework; disclose to PM immediately on discovery |
| Vendor-side delays during cutover (Pega, FinanceOne, Maximo) | M5 | Engage vendor contacts during Wave 1; confirm availability windows early |

### Calendar assumptions
- 3-engineer team starting mid-2026
- Realistic availability factored in (leave, BAU commitments, onboarding ramp-up for new engineers)
- Wave 2 is the primary parallelisation window (Engineers 1 and 2 work concurrently on different integration groups)
- Wave 1 must complete before Wave 2 bulk work begins
- Wave 3 runs in series at the end due to complexity and coordination requirements

### Escalation reserve
A 70-day escalation reserve is included in the estimate and is available across all waves. This buffer is not pre-allocated — it activates when late-breaking discoveries (undocumented adapters, EDI integrations, extended parallel runs, rework cycles) are confirmed. Any draw on this reserve will be reported to the project manager immediately.
