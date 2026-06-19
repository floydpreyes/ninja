# Risk Register

Risks that drive scenario choice (see [02-scenario-model.md](02-scenario-model.md)).
Likelihood and impact rated **before** mitigation.

## Top risks

| # | Risk | Likelihood | Impact | Scenario implied if realised | Primary mitigation |
|---|---|---|---|---|---|
| 1 | BizTalk SME unavailable or part-time only | Med | High | C → D | Lock SME 0.5 FTE in Wave 1; document patterns aggressively to reduce later dependency |
| 2 | External partner contract change cycle (Pega, FinanceOne, ESRI) | High | Med | C minimum | Engage owners in Wave 1; preserve external contracts via APIM where possible |
| 3 | Cloud security perimeter delivered late | Med | Med | C, mitigated via Logic Apps hybrid runtime | Use hybrid runtime as fallback; perimeter not on AIS critical path |
| 4 | HYBRID rewrites have bespoke logic that won't template | Med | High | C → D | Pilot DrainageInfo first; if it doesn't compress, raise scope flag |
| 5 | Production incident during cutover causes pause | Low | Med | D buffer absorbs | APIM-based instant rollback; 30-day quiet period before decom |
| 6 | Engineer leave / illness > 2 weeks | Med | Med | C-fast or D | Cross-training in Wave 1; documented patterns; 3rd engineer as buffer |
| 7 | Discovery reveals undocumented BizTalk features (BAM, BRE, EDI, custom adapters) | Med | Low–Med | C buffer absorbs; E if EDI/custom adapter | Run aimbiztalk + Documenter early; flag in Wave 1 retro |
| 8 | Inflight BizTalk changes during migration | Med | Low | Folded into discovery refresh per wave | Re-run discovery at start of each wave |
| 9 | APIM Premium tier capacity limits hit | Low | Med | None — sizing exercise | Capacity plan during Wave 1 build |
| 10 | Service Bus Premium messaging unit sizing wrong | Low | Low | None | Right-size during Wave 2 first integration |
| 11 | Stakeholder turnover (named owner leaves) | Med | Med | Wave-specific elapsed +1–2 wks | RACI with backups for each owner |
| 12 | Network team can't deliver private endpoints in time for Wave 1 pilots | Low | High | W1 starts late | Engage network team alongside Wave 1 prep; hybrid runtime as fallback |
| 13 | Source code missing for older integrations | Med | Med | E for affected integrations only | Run Documenter on deployed BizTalk apps to reverse-engineer |
| 14 | BAM tracking requirements not surfaced until late | Low | Med | +5d per affected integration | Question 4 in [07-questionnaire.md](07-questionnaire.md) catches this |
| 15 | EDI usage discovered (not visible in CSV) | Low | High | Out of scope; treat as separate workstream | Question 15 in questionnaire catches this |

## Decision triggers

Move from **Scenario C → D** if any of the following becomes true during
Wave 1:
- BizTalk SME availability drops below 0.5 FTE for any 2-week period
- A partner (Pega, ESRI, FinanceOne) confirms multi-week response cadence
- Wave 1 surfaces undocumented components (custom adapters, EDI, significant
  BAM usage)
- A production-class incident causes a Wave 1 cutover rollback

Move from **D → E** only with explicit programme-board approval — at this
point we should also reconsider scope (retire vs migrate) for low-value
interfaces.

## Risks we are explicitly accepting (do not mitigate)

| Risk | Why accepted |
|---|---|
| BizTalk 2016 EOL Jan 2027 before programme finish | Extended support paid in parallel; not a hard outage risk |
| Logic Apps consumption-cost variability vs BizTalk fixed cost | Net programme TCO improves; FinOps owns ongoing optimisation |
| Some legacy SOAP clients remain on SOAP after migration | APIM exposes SOAP front-end to internal Logic App REST — clients unchanged |
| BizTalk 2020 bridge upgrade not pursued | Extended support is cheaper and avoids double migration |

## Risks under separate workstreams (not owned by this programme)

| Risk | Owner |
|---|---|
| Cloud security perimeter design + delivery | MW Network/Platform team |
| 13-WaterWorks (CGI vendor) | CGI |
| Connected-system re-architecture (Pega, Maximo, etc.) | Respective system owners |
| MW Azure landing zone governance changes | MW Cloud Platform team |

## Review cadence

- Risk register reviewed at end of every wave
- Top-3 risks reviewed weekly during Wave 1
- Trigger-based re-baseline (C → D → E) requires programme-board sign-off
