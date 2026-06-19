# BizTalk → Azure Integration Services Migration

Solution artefacts for Melbourne Water's BizTalk 2016 → AIS migration programme.
Source evidence (CSVs, original docs, architecture diagram) lives in the parent
folder; this folder contains the planning deliverables built from that evidence.

## Reading order

1. [01-stakeholder-summary.md](01-stakeholder-summary.md) — one-page summary, start here
2. [02-scenario-model.md](02-scenario-model.md) — five scenarios A–E + fast variants, with reasoning
3. [03-architecture.md](03-architecture.md) — BizTalk → AIS component map with rationale
4. [04-roadmap.md](04-roadmap.md) — 3-wave delivery plan
5. [05-phase1-detail.md](05-phase1-detail.md) — Wave 1 pilot interfaces, build + cutover detail
6. [06-effort-estimation.md](06-effort-estimation.md) — estimation framework + skills demand profile
7. [07-questionnaire.md](07-questionnaire.md) — short SME interview to validate assumptions
8. [08-risk-register.md](08-risk-register.md) — risks that drive scenario choice

## Recommendation

Commit to **Scenario C** (13 months, 2 engineers, ~800 person-days, finishing
Jul 2027). Execute against **Scenario B as a stretch target**. See
[02-scenario-model.md](02-scenario-model.md) for the full picture.

## Scope summary

| | |
|---|---|
| In scope | ~55 BizTalk integrations across 18 application groups |
| Out of scope | 13-WaterWorks (CGI), 18-BizTalk system apps (decom only), 20-Flash Flood (retire) |
| Excluded workstreams | Cloud security perimeter (separate network workstream), connected-system re-architecture |
| Hard deadline | BizTalk 2016 EOL Jan 2027; extended support runs in parallel |
| Recommended start | Mid-2026 |

## Source evidence used

- [../Interface_Details.csv](../Interface_Details.csv) — full interface inventory
- [../Detail1.csv](../Detail1.csv), [../Detail2.csv](../Detail2.csv) — pivot extracts
- [../biztalk-docs-full/docs/architecture.md](../biztalk-docs-full/docs/architecture.md)
- [../biztalk-docs-full/docs/options.md](../biztalk-docs-full/docs/options.md)
- [../biztalk-docs-full/docs/overview.md](../biztalk-docs-full/docs/overview.md)
- [../biztalk-docs-full/docs/service-owners.md](../biztalk-docs-full/docs/service-owners.md)
- [../biztalk-docs-full/data/integration-catalog.md](../biztalk-docs-full/data/integration-catalog.md)
- Architecture diagram (image) supplied by SME

## Open assumptions (validate via questionnaire)

- BizTalk runtime components (pipelines, maps, MessageBox correlation, ESB Toolkit
  use) are inferred from standard BizTalk 2016 deployments — **not** evidenced in
  the source files. See [07-questionnaire.md](07-questionnaire.md) for validation
  questions.
- Throughput / message-size profile per integration unknown.
- BizTalk SME availability assumed at 0.5 FTE during W1, on-call thereafter.
