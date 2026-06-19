# Stakeholder Summary

**BizTalk 2016 → Azure Integration Services migration for Melbourne Water.**

## At a glance

| | |
|---|---|
| **Scope** | ~55 in-scope BizTalk integrations across 18 application groups |
| **Excluded** | 13-WaterWorks (CGI-managed), 18-BizTalk system apps (decom only), 20-Flash Flood (retire) |
| **Approach** | 3 waves: pattern templates → CAPEX bulk → HYBRID rewrites + decommission |
| **Platform** | Logic Apps Standard, APIM (existing), Service Bus Premium, Functions, Storage — built on MW's existing AVM Bicep + CI/CD patterns |
| **Hard deadline** | BizTalk 2016 EOL Jan 2027; extended support runs in parallel as safety net |
| **Recommended start** | Mid-2026 |
| **Recommended team** | 2 in-house DevOps engineers (strong Azure + Python + 1 .NET) |
| **Recommended baseline** | **Scenario C — 13 months, ~800 person-days, finishing Jul 2027** |
| **Stretch target** | Scenario B — 10 months, ~620 person-days, finishing Apr 2027 |

## Why an aggressive baseline is credible

1. **Platform foundations already in place** — no Wave 0 needed (AVM Bicep modules, CI/CD pipelines, APIM all exist in MW today)
2. **~55 interfaces collapse to ~6 patterns** — first-of-pattern build cost amortises across the portfolio (typical 2.5–3× speedup after first instance)
3. **APIM-fronted cutover** = single-config rollback; low-risk per integration
4. **Phase 1 pilots de-risk ~70% of remaining work** by proving every recurring pattern
5. **Most CAPEX integrations are independent** — true parallelism is achievable with 2 engineers
6. **Extended support window absorbs slippage** without business impact

## Decisions we need from stakeholders

1. **Pick a scenario** (A–E or fast variants) — drives commitment date and budget. See [02-scenario-model.md](02-scenario-model.md).
2. **Confirm BizTalk SME allocation** — single biggest risk multiplier
3. **Decide on 3rd engineer** for fast variants — cost vs schedule trade-off
4. **Confirm cloud security perimeter delivery date** — or approve Logic Apps hybrid-runtime fallback
5. **Approve Phase 1 pilot interfaces** — Maximo Mobility Attachment, DevConnect DrainageInfo, AMIS Q4
6. **Approve scope exclusions** — 13-WaterWorks, 18-BizTalk, 20-Flash Flood
7. **Approve external partner engagement model** — Pega, ESRI, FinanceOne, Zycus, TechOne owners

## Recommended ask

> "We propose **Scenario C (13 months, 2 engineers, ~800 person-days, finishing
> July 2027)** as our committed baseline. We will execute against **Scenario B as
> a stretch target**. If the BizTalk SME is unavailable or external partner
> cadence is slower than weekly, we move to **Scenario D**. A 3rd engineer
> (C-fast) would compress the finish to March 2027 if business value justifies
> the cost."

## Next steps if approved

1. Run the SME questionnaire ([07-questionnaire.md](07-questionnaire.md)) — week 1
2. Run aimbiztalk + BizTalk Documenter against the BizTalk environment — weeks 1–2
3. Lock the per-interface complexity scoring — week 3
4. Begin Wave 1 pilot builds — week 4

## Risks driving scenario choice

See [08-risk-register.md](08-risk-register.md). Top three:

- BizTalk SME availability (drives C → D shift)
- External partner cadence (Pega, FinanceOne) (drives W3 elapsed time)
- HYBRID rewrites containing bespoke logic that won't template (drives build cost)
