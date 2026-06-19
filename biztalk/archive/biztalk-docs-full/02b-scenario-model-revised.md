# Scenario Model — Revised (DevOps engineering effort only)

Three scenarios using tighter per-bucket day estimates. **Effort shown is
DevOps engineering effort only** — programme/project management, change
management lead times, CAB approvals, and stakeholder scheduling are
out of scope here and owned by the programme manager / project manager.

## Scope of these numbers

**In scope (counted):**
- Discovery + interface analysis by engineers
- Build (Bicep, Logic Apps, Functions, APIM, transforms, tests)
- Cutover execution + parallel-run monitoring
- Engineering risk contingency (technical unknowns)

**Out of scope (PM owns):**
- Programme management overhead (stand-ups, reporting, planning)
- Change management lead times, CAB cycles, freeze periods
- Stakeholder workshop scheduling and wait time
- External partner contract / commercial lead time
- Calendar slip from organisational dependencies

The PM should layer those on top of the engineering numbers below to produce
the committed delivery date.

## Renumbering reference

| New label | Old label | Stance |
|---|---|---|
| **A — Aggressive ⭐** | C — Realistic | Recommended baseline |
| **B — Safe** | D — Safe | If 1 named risk materialises |
| **C — Conservative** | E — Conservative | If 2+ named risks materialise |

## Per-bucket estimates

| Bucket | First-of-pattern (d) | Subsequent (d) |
|---|---|---|
| Simple | 5 | 2 |
| Standard | 8 | 4 |
| Complex | 10 | 6 |
| Very complex | 15 | 8 |

## Indicative bucket counts (must be validated by discovery)

| Bucket | Count | Of which: first | Of which: subsequent |
|---|---|---|---|
| Simple | ~8 | 1 | 7 |
| Standard | ~22 | 1 | 21 |
| Complex | ~20 | 1 | 19 |
| Very complex | ~5 | 1 | 4 |
| **Total interfaces** | **~55** | **4** | **51** |

## Headline comparison (engineering effort only)

| Scenario | Engineering effort | Engineers | Engineering calendar (with parallelism) | Earliest engineering finish (start Jun 2026) | Engineering contingency |
|---|---|---|---|---|---|
| **A — Aggressive ⭐** | **~480 d** | 2 | **9 mo** | **Mar 2027** | +35% |
| **B — Safe** | **~580 d** | 2 | **10 mo** | **Apr 2027** | +60% |
| **C — Conservative** | **~720 d** | 2 | **13 mo** | **Jul 2027** | +75% |
| A-fast (3 engineers) | 480 d | 3 | 7 mo | Jan 2027 | +35% |
| B-fast (3 engineers) | 580 d | 3 | 8 mo | Feb 2027 | +60% |
| C-fast (3 engineers) | 720 d | 3 | 10 mo | Apr 2027 | +75% |

The "earliest engineering finish" excludes any PM-owned calendar (CAB lead
times, freeze periods, stakeholder availability). The PM converts these into
a committed business date.

All three scenarios share the same **engineering build subtotal of 282 d**.
The difference between them is in the engineering wrapper (cutover policy,
contingency, surprise reserves).

---

## Build effort (common to all three scenarios)

| Bucket | First (d) | Subseq (d) | First × 1 | Subseq × n | Subtotal |
|---|---|---|---|---|---|
| Simple | 5 | 2 | 5 | 7 × 2 = 14 | **19** |
| Standard | 8 | 4 | 8 | 21 × 4 = 84 | **92** |
| Complex | 10 | 6 | 10 | 19 × 6 = 114 | **124** |
| Very complex | 15 | 8 | 15 | 4 × 8 = 32 | **47** |
| **Build subtotal** | | | | | **282** |

---

## Scenario A — Aggressive (recommended baseline)

### Engineering effort

| Item | Calc | Days |
|---|---|---|
| Build subtotal | | 282 |
| Discovery (per app group) | ~20 × 2 d | 40 |
| Cutover + parallel run | +20% of build (1-week parallel run) | 56 |
| Subtotal pre-contingency | | **378** |
| Engineering risk contingency | +35% of build | 99 |
| **Scenario A engineering total** | | **~480 d** |

### Calendar math (engineering only)

- 2 engineers × 17.5 d/mo × 60% parallelism factor ≈ **56 d/mo effective**
- 480 d ÷ 56 d/mo ≈ **9 months**
- Engineering start Jun 2026 → engineering finish **Mar 2027**
- A-fast (3 engineers): 480 ÷ ~75 d/mo ≈ **7 months** → **Jan 2027**

### What Scenario A buys you

- Realistic engineering cadence with templated patterns
- Standard 1-week parallel-run per integration
- 35% engineering contingency for nameable Wave 1 surprises
- Engineering finishes ~2 months after BizTalk 2016 EOL — extended support
  covers any PM calendar overrun
- A-fast pulls engineering finish into **Jan 2027**

### Wave allocation

| Wave | Engineering effort | Engineering months |
|---|---|---|
| W1 — pattern templates + 3 pilots | ~75 d | 2 |
| W2 — CAPEX bulk migration | ~270 d | 5 |
| W3 — HYBRID rewrites + decom | ~135 d | 2 |
| **Total** | **~480 d** | **~9 mo** |

---

## Scenario B — Safe

Use this if **one** of the named risks is realised (or strongly likely):

- BizTalk SME availability uncertain or below 0.5 FTE
- Risk-averse cutover policy required (2-week parallel run per integration)
- One Wave 1 technical surprise expected

### Engineering effort

| Item | Calc | Days |
|---|---|---|
| Build subtotal | (same as A) | 282 |
| Discovery (per app group) | ~20 × 2 d, +small surprise reserve | 46 |
| Cutover + parallel run | **+30% of build** (2-week parallel run) | 85 |
| Subtotal pre-contingency | | **413** |
| Engineering risk contingency | **+60% of build** | 169 |
| **Scenario B engineering total** | | **~580 d** |

### How B gets to 580 d from A's 480 d

| Increment | Days added | Why |
|---|---|---|
| A baseline | 480 | – |
| Longer parallel run (1 wk → 2 wk per integration) | +29 | Risk-averse cutover policy |
| Discovery surprise reserve | +6 | One Wave 1 surprise expected |
| Extra contingency (+35% → +60%) | +70 | One named risk materialises |
| Rounding | −5 | – |
| **Scenario B total** | **~580** | |

### Calendar math (engineering only)

- 580 d ÷ 56 d/mo ≈ **10 months**
- Engineering start Jun 2026 → engineering finish **Apr 2027**
- B-fast (3 engineers): 580 ÷ ~75 d/mo ≈ **8 months** → **Feb 2027**

### Wave allocation

| Wave | Engineering effort | Engineering months |
|---|---|---|
| W1 — pattern templates + 3 pilots | ~90 d | 2 |
| W2 — CAPEX bulk migration | ~320 d | 6 |
| W3 — HYBRID rewrites + decom | ~170 d | 2 |
| **Total** | **~580 d** | **~10 mo** |

---

## Scenario C — Conservative

Use this if **two or more** of the named risks are realised (or very likely):

- BizTalk SME availability uncertain or below 0.5 FTE
- Discovery has not yet confirmed source code is in source control
- High likelihood of EDI / custom adapter / BAM surprises
- Risk-averse cutover policy (2-week parallel run + extra dress rehearsal)

### Engineering effort

| Item | Calc | Days |
|---|---|---|
| Build subtotal | (same as A and B) | 282 |
| Discovery | ~20 × 2 d, +15% surprise reserve | 46 |
| Cutover + parallel run | **+35% of build** (2-week parallel run + extra dress rehearsal) | 99 |
| Subtotal pre-contingency | | **427** |
| Engineering risk contingency | **+75% of build** | 212 |
| Discovery surprise reserve (broad-based) | **+15% across the board** | ~77 |
| **Scenario C engineering total** | | **~720 d** |

### How C gets to 720 d from A's 480 d

| Increment | Days added | Why |
|---|---|---|
| A baseline | 480 | – |
| Longer parallel run (1 wk → 2 wk + extra rehearsal) | +43 | Risk-averse cutover policy |
| Discovery surprise reserve (broad-based +15%) | +77 | Undocumented BAM / BRE / EDI / custom adapters |
| Extra contingency (+35% → +75%) | +113 | Two named risks materialise simultaneously |
| Rounding | +7 | – |
| **Scenario C total** | **~720** | |

### Calendar math (engineering only)

- 720 d ÷ 56 d/mo ≈ **13 months**
- Engineering start Jun 2026 → engineering finish **Jul 2027**
- C-fast (3 engineers): 720 ÷ ~75 d/mo ≈ **10 months** → **Apr 2027**

### Wave allocation

| Wave | Engineering effort | Engineering months |
|---|---|---|
| W1 — pattern templates + 3 pilots | ~105 d | 3 |
| W2 — CAPEX bulk migration | ~395 d | 7 |
| W3 — HYBRID rewrites + decom | ~220 d | 3 |
| **Total** | **~720 d** | **~13 mo** |

---

## Side-by-side comparison (engineering effort only)

| Dimension | A — Aggressive | B — Safe | C — Conservative |
|---|---|---|---|
| Total engineering effort | 480 d | 580 d | 720 d |
| Build subtotal | 282 d | 282 d | 282 d |
| Discovery | 40 d | 46 d | 46 d |
| Cutover + parallel run | 56 d (+20%) | 85 d (+30%) | 99 d (+35%) |
| Engineering risk contingency | 99 d (+35%) | 169 d (+60%) | 212 d (+75%) |
| Discovery surprise reserve | – | – | 77 d (+15%) |
| Engineers | 2 | 2 | 2 |
| Engineering calendar (with parallelism) | 9 mo | 10 mo | 13 mo |
| Earliest engineering finish (start Jun 2026) | **Mar 2027** | **Apr 2027** | **Jul 2027** |
| Parallel-run period per integration | 1 wk | 2 wk | 2 wk + extra rehearsal |
| Survives 1 named risk? | Yes (uses contingency) | Yes (with margin) | Yes (with margin) |
| Survives 2 named risks? | Marginal — re-baseline trigger | Marginal — re-baseline trigger | Yes |
| Extra cost vs A | – | +100 d (~3 person-months) | +240 d (~7 person-months) |

## What the PM/programme manager needs to layer on top

The numbers above are **engineering effort and engineering calendar only**.
The PM owns:

| PM-owned item | Likely impact on committed date |
|---|---|
| Programme management overhead (own time, not engineers') | – |
| Change management — CAB lead time per cutover | +1–10 d elapsed per cutover, depending on classification |
| Change freeze periods (Christmas, EOFY, audit) | Compresses available cutover weeks |
| Stakeholder workshop scheduling | Elapsed only — folded into wave start dates |
| External partner cadence (Pega, ESRI, FinanceOne) | Drives W3 sub-stream sequencing |
| Inter-team dependencies (network, identity, security) | Drives W1 readiness gate |
| Communications, training, ops handover | Owned alongside Wave 3 decom |

Suggested approach: take the engineering finish date and add a PM-owned
calendar buffer derived from MW change-management policy (e.g. +1 month for
standard CAB cycles, +2 months if any cutovers fall inside an EOFY freeze).

## Recommendation

1. **Commit Scenario A engineering effort (~480 d)** with the +35%
   engineering contingency held visibly.
2. PM layers change management + freeze-period calendar on top to produce
   the business commitment date.
3. Re-baseline engineering effort to **Scenario B** at end of Wave 1 if **one**
   trigger condition has materialised
   (see [08-risk-register.md](08-risk-register.md)).
4. Re-baseline to **Scenario C** at end of Wave 1 only if **two or more**
   trigger conditions have materialised.
5. Offer **A-fast** (3 engineers) as the option for stakeholders who need
   engineering finish in **Jan 2027** to align with BizTalk EOL.

## What this version assumes

These tighter per-bucket numbers depend on discovery confirming:

- BizTalk source code is in source control and `aimbiztalk` runs cleanly
- A BizTalk SME is allocated ≥ 0.5 FTE through Wave 1
- Most "complex" integrations are pattern-similar (true bespoke HYBRID
  volume is small — perhaps 5 of the ~20 Complex bucket)
- No EDI / custom adapter / large BAM footprint surfaces in discovery

If any of those is uncertain at programme start, lead stakeholder
conversations with Scenario B engineering numbers, not A.
