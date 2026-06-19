# Roadmap — 3 Waves

No Wave 0 (MW DevOps already provides AVM Bicep, CI/CD, APIM). Discovery folded
into Wave 1 prep. Shared library built incrementally, not designed up front.

## Wave 1 — Pattern Templates (Months 1–2 in any scenario)

**Goal:** Prove every recurring pattern via the three CSV-marked Phase 1
interfaces. Outputs become templates that subsequent waves clone.

**Deliverables:**
- Three production-ready integrations (see [05-phase1-detail.md](05-phase1-detail.md))
- Reusable Logic App templates per pattern
- APIM API + product templates
- Per-pattern cutover runbook
- Alert-parity baseline against BizTalk360
- Discovery outputs: aimbiztalk + BizTalk Documenter reports across the BizTalk
  estate, plus SME interview answers

**Patterns proven:**
- On-prem → on-prem API (Maximo Mobility Attachment)
- HYBRID rewrite (DevConnect DrainageInfo)
- Scheduled file batch (AMIS Q4)

**SME demand:** High — must validate every pattern decision

## Wave 2 — CAPEX Bulk Migration (Months 3–7 in scenario B; longer in C–E)

**Goal:** Lift-and-replatform the standard CAPEX integrations using Wave 1
templates. Sequenced by independence and service-owner clustering.

**Approximate ordering (low-risk first, owner-batched):**
1. 01-PageUp-Chris21 + 06-IRIS (Terena Barnes — owns multiple, batch)
2. 04-Liquid-EnviroSys
3. 05-Project Online (3 interfaces, single owner)
4. 10-AMIS remainder
5. 14-Procurement (6 interfaces, single owner — Maximo)
6. 16-Zycus (6 interfaces — Vimmi Grover)
7. 17-Incentive (5 interfaces — same Pega→ESRI shape, big reuse opportunity)
8. 03-Kronos-Maximo
9. 07-SmartRain (2 interfaces)

**Per-integration approach:**
- Clone template
- Configure connectors + auth (managed identity + Key Vault refs)
- Port transforms (Liquid/XSLT or Function)
- Parallel run 1–2 weeks (longer in safer scenarios)
- APIM backend swap cutover
- Alert parity verified
- Decom BizTalk app after 30 days zero traffic

**SME demand:** Medium — pattern recognition, occasional questions

## Wave 3 — HYBRID Rewrites + Decommission (Months 8–10/13/17/20 depending on scenario)

**Goal:** Full code rewrites for the HYBRID-treatment app groups (~25
sub-interfaces), then BizTalk shutdown.

**Sub-streams (parallelisable with 2 engineers):**
- **Stream A — Pega/ESRI:** 08-DevConnect remainder (~12 APIs), 19-CAD (2),
  09-Chris21 Enterprise Services. Common shape — `MW.Incentive.Grants.*` from
  Wave 2 already proves the pattern.
- **Stream B — Finance One ↔ Maximo:** 12-DFWS (6 API rewrites)
- **Stream C — IDAM/Chris21:** 15-IDAM Chris21 Common, IDAM Chris21 Integration

**Per-integration approach:**
- Read existing BizTalk orchestration (with SME)
- Port helper assemblies to .NET Functions
- Build Logic App orchestration replacing XLANG/s
- Contract review with partner (Pega/FinanceOne/Maximo owner)
- Shadow traffic 2 weeks, byte-comparison reconciliation
- Phased traffic split (10% → 50% → 100%) over 1 week
- Alert parity verified

**Decommission tail (final ~2 weeks):**
- Final BizTalk app shutdowns
- Server decom: SVBTSPROD01–04 (BizTalk core), SVBTSPROD05 (BizTalk360),
  SVBZWEBPROD01/02 (WCF Routers)
- Network rule cleanup (DMZ, NetScaler, internal firewall)
- Lessons-learned, CMDB updates, run-book handover to operations

**SME demand:** High — bespoke business logic must be understood before rewrite

## Dependencies between waves

- Wave 2 cannot start until **at least one** Wave 1 pattern is in production
- Wave 3 cannot start until Wave 2's Pega→ESRI flows are in production
  (proves the rewrite shape on a low-stakes integration first —
  `MW.Incentive.Grants.*`)
- Decom tail cannot start until 30 days zero traffic on the BizTalk app

## Cross-wave activities

- Discovery (~40d): runs through Wave 1 prep + first 2 weeks of Wave 1
- Cutover runbook authoring: maintained per pattern, refined each wave
- Alert parity matrix: extended each wave
- Stakeholder workshops: weekly through Wave 2/3, bi-weekly otherwise
- Run-book handover: starts Wave 3, finalised at decom

## Critical-path observations

- Wave 1 is **not** parallelisable (templates feed everything else)
- Wave 2 is **highly parallelisable** — 2 engineers can run 4–6 in flight
- Wave 3 is **partially parallelisable** — 3 sub-streams but external partner
  cadence is the limiter, not engineer count
- Decom is sequential — one app at a time, 30-day quiet period each
