# Effort Estimation Framework + Skills Demand

## Estimation model

```
Total effort = Σ (interfaces × per-interface cost) + fixed overheads
```

Per-interface cost uses a **first-of-pattern + subsequent** model — the single
biggest defensible compression factor.

### Step 1 — Categorise every interface by complexity

The CSV's CAPEX/HYBRID label is *commercial*. For estimation, score each
interface against four technical drivers:

| Driver | Why it matters | Low (1) | Medium (2) | High (3) |
|---|---|---|---|---|
| **Pattern complexity** | Workflow shape | Pass-through / file copy | Request-response with transform | Stateful, correlation, long-running |
| **Transformation complexity** | Map vs Function decision | Field rename / passthrough | Structural reshape (Liquid/XSLT) | .NET helper / BRE / DB lookup |
| **Connectivity complexity** | Connector + auth work | HTTP + key/MI | SOAP / on-prem + gateway | Custom adapter / legacy auth / no native connector |
| **Stakeholder complexity** | Elapsed time, not effort | 1 owner, internal | 2 owners, internal | External partner, contract change, multi-owner |

**Composite score** (sum, range 4–12) → bucket:
- **Simple** (4–5): file move, basic API pass-through
- **Standard** (6–8): typical CAPEX integration
- **Complex** (9–10): typical HYBRID rewrite
- **Very complex** (11–12): DevConnect-style multi-system rewrite

### Step 2 — Per-bucket day estimates (with learning curve)

| Bucket | First-of-pattern (d) | Subsequent (d) | Compression factor |
|---|---|---|---|
| Simple | 7 | 3 | 57% |
| Standard | 12 | 5 | 58% |
| Complex | 22 | 10 | 55% |
| Very complex | 36 | 20 | 44% |

**Why these numbers are defensible:**
- First-of-pattern includes pattern design, Bicep authoring, dashboard build,
  cutover runbook authoring, dress-rehearsal scripting, parallel-run tooling
- Subsequent integrations are clone + parameter changes + transform work +
  cutover execution
- Industry benchmark is 3–4× speedup after first instance — we use only ~2.5×,
  leaving conservative margin

### Step 3 — Fixed overheads (% of build, scale with scope)

| Overhead | % | Covers |
|---|---|---|
| Discovery (per app group) | +10% | aimbiztalk runs, SME interviews, cataloguing |
| Cutover + parallel run | +20–25% | dress rehearsals, traffic switch, monitoring period |
| Programme management | +10% | stand-ups, planning, reporting, retros |
| Risk contingency | +5% to +30% | unknowns surfaced during discovery; varies by scenario |

### Step 4 — Convert to calendar

```
Capacity = engineers × productive_days_per_year × parallelism_factor
```
- Productive days/engineer/year ≈ 200–220
- Parallelism factor: 1.0 (1 engineer), ~0.95 (2), ~0.85 (3+)
- Wave 1 is non-parallelisable (template build)
- Wave 2 is highly parallel
- Wave 3 is partially parallel (3 sub-streams, partner cadence limits)

See [02-scenario-model.md](02-scenario-model.md) for the resulting matrix.

## Indicative bucket counts (refine after discovery)

Estimated from CSV evidence — **must be validated** by SME questionnaire +
aimbiztalk discovery before stakeholder commitment.

| Bucket | Count | Examples (from CSV) |
|---|---|---|
| Simple | ~8 | AMIS Q4, IDAM Chris21 batch, P3I batch flows |
| Standard | ~22 | Procurement (×6), Zycus (×4), Maximo Mobility, IRIS |
| Complex | ~20 | Incentive Grants (×5), DevConnect simple cases, DFWS basic |
| Very complex | ~5 | DevConnect multi-system, DFWS Reimbursement, CAD bespoke |

## Skills demand profile across waves

| Skill | W1 | W2 | W3 | Decom | Cover via |
|---|---|---|---|---|---|
| Logic Apps Standard, APIM, Service Bus | High | High | High | – | Lead engineer |
| Bicep + AVM (consume existing modules) | Low | Low | Low | – | Either engineer |
| .NET / C# (BizTalk helper porting) | Low | Low | High | – | Second engineer or contractor |
| Python (transform Functions, tooling) | Med | Med | Med | – | Lead engineer |
| **BizTalk SME** (read existing artefacts) | High | Med | High | Low | **Internal MW resource — gating** |
| Networking / hybrid runtime | High | Med | Low | – | MW network team (existing) |
| Identity / Key Vault / managed identity | High | Med | Med | – | Either engineer |
| Test / QA, parallel-run reconciliation | Med | High | High | – | Either engineer + automation |
| Stakeholder / partner coordination | Med | High | High | – | PM + lead engineer |
| Run-book authoring | Low | Med | Med | High | Either engineer |

## Skill-to-role mapping (illustrative)

| Role | Primary skills | Indicative FTE-equivalent |
|---|---|---|
| Lead Integration Engineer | Logic Apps + APIM + Service Bus + design | ~1 FTE throughout |
| Build Engineer | Logic Apps + Bicep + observability | scales with scope |
| .NET / Transform Engineer | C# Functions + BizTalk helper porting | 0.3 FTE early, ~1 FTE in W3 |
| BizTalk SME | Read existing artefacts, validate parity | 0.5 FTE in W1, ~0.3 FTE W2/W3 |
| Network / Platform | Hybrid runtime, gateway, perimeter | 0.2–0.5 FTE, peaks at perimeter cutover |
| Test / QA | Parallel-run reconciliation, synthetic tx | 0.5–1 FTE W2/W3 |
| Programme / cutover lead | Sequencing, stakeholders, change control | 0.3–0.5 FTE throughout |

## Insights for stakeholder conversations

1. **The BizTalk SME is the single biggest risk variable.** If MW has one and
   they're available, Complex/Very-complex day estimates can use the **low**
   end. If not, use the **high** end and add 20% to discovery.
2. **The .NET skill is bursty, not continuous** — concentrated in Wave 3. A
   contractor or part-time allocation is often more efficient than permanent.
3. **Test/QA is consistently under-estimated** — break it out as a budget line
   so it doesn't get squeezed.
4. **Stakeholder/partner coordination is elapsed time, not effort.** Adding
   engineers doesn't speed up Wave 3 if Pega/ESRI/Finance One owners can only
   attend one workshop a fortnight.

## How to use this with stakeholders

1. Run discovery (aimbiztalk + Documenter + SME interviews) — produces real
   interface list with complexity scoring
2. Fill in bucket counts for the actual portfolio
3. Present **three scenarios** (low / likely / high) × **two team sizes** —
   see [02-scenario-model.md](02-scenario-model.md)
4. Layer on the skills demand chart — shows which skills must be in-house vs
   partner/contract
5. Let stakeholders pick a corner and you can defend the assumptions behind
   any cell
