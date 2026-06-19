# Scenario Model

Five baseline scenarios + two "fast" variants with a 3rd engineer. Pick a corner;
each successive scenario relaxes one assumption.

## Scenarios

| Scenario | Effort (person-days) | Engineers | Calendar | Finish (start mid-2026) | Contingency held | Best for… |
|---|---|---|---|---|---|---|
| **A — Best case** | 480 | 2 | 8 mo | Feb 2027 | +5% | Demo of what's possible if everything goes right (do not commit) |
| **B — Aggressive** | 620 | 2 | 10 mo | Apr 2027 | +20% | Stretch target if risk tolerance is high |
| **C — Realistic ⭐** | 800 | 2 | 13 mo | **Jul 2027** | +35% | **Recommended baseline for stakeholder commitment** |
| **D — Safe** | 1,000 | 2 | 17 mo | Nov 2027 | +50% | If 2 of the named risks materialise |
| **E — Conservative** | 1,200 | 2 | 20 mo | Feb 2028 | +60% | Risk-averse, broad partner dependencies |
| **C-fast** | 800 | 3 | 9 mo | Mar 2027 | +35% | Realistic scope, faster finish, +1 FTE cost |
| **D-fast** | 1,000 | 3 | 11 mo | May 2027 | +50% | Safe scope, faster finish, +1 FTE cost |

## Effort breakdown (Scenario B, aggressive baseline)

| Bucket | First-of-pattern (d) | Subsequent (d) | Count | Subtotal |
|---|---|---|---|---|
| Simple (file/pass-through) | 7 | 3 | ~8 | 28 |
| Standard (API + transform) | 12 | 5 | ~22 | 117 |
| Complex (HYBRID rewrite) | 22 | 10 | ~20 | 212 |
| Very complex (multi-system) | 36 | 20 | ~5 | 116 |
| Discovery (per app group) | – | – | ~20 × 2d | 40 |
| **Build subtotal** | | | | **513** |
| Cutover / parallel run (+15%) | | | | 77 |
| Programme overhead (+5%) | | | | 26 |
| **Total** | | | | **~620 d** |

Scenarios C–E inflate this by relaxing the assumptions below.

## What changes between scenarios

| From → To | Assumption relaxed | Why it adds time |
|---|---|---|
| **A → B** | Template reuse efficiency 70% → 60% | Some patterns won't compress as cleanly as hoped |
| **B → C** | Stakeholder workshop cadence 1 wk → 2 wk for external partners | Pega / ESRI / FinanceOne realistic response time |
| **C → D** | Add a 2-week parallel-run period per integration (was 1 week) | Risk-averse cutover policy on PROD |
| **D → E** | Add 15% across the board for discovery surprises | Undocumented BAM / BRE / EDI usage in BizTalk |
| **C → C-fast** | Add 3rd engineer (~5% coordination tax) | Parallelism in W2 / W3 |

## Calendar math (capacity per month)

- Productive days/engineer/year ≈ 210
- Per engineer per month ≈ 17.5 days
- 2 engineers ≈ 35 d/mo
- 3 engineers ≈ 50 d/mo (5% coordination overhead)

| Total effort | 2 engineers | 3 engineers |
|---|---|---|
| 480 d | 14 mo (compressed via parallelism in best case) — 8 mo realistic | 10 mo |
| 620 d | 18 mo theoretical / **10 mo with 60% parallelism** | 12 mo |
| 800 d | 23 mo theoretical / **13 mo with 60% parallelism** | 16 mo / **9 mo with parallelism** |
| 1,000 d | 28 mo theoretical / 17 mo with parallelism | 11 mo with parallelism |
| 1,200 d | 34 mo theoretical / 20 mo with parallelism | 13 mo with parallelism |

The "with parallelism" figures assume 60% effective parallelism across two
streams (i.e. two engineers averaging ~1.6× single-engineer throughput once
template reuse and dependency batching kick in from Wave 2 onwards).

## Why we recommend Scenario C

- Credible to commit publicly without overrun risk
- Leaves real contingency (+35%) for the unknowns we can name
- Finishes 6 months before the BizTalk extended-support buffer would be exhausted
- Allows Scenario B to be quietly executed as a stretch target without
  re-baselining if everything goes well
- Trade to C-fast (3rd engineer) is reversible if budget tightens mid-programme

## When to escalate to D / E

Move from C → D if **any** of the following becomes true during Wave 1:

- BizTalk SME availability drops below 0.5 FTE for any 2-week period
- A partner (Pega, ESRI, FinanceOne) confirms multi-week response cadence
- Wave 1 surfaces undocumented BizTalk components (custom adapters, EDI,
  significant BAM usage)
- A production-class incident causes a Wave 1 cutover rollback

Move from D → E only with explicit programme-board approval — at this point
we should also reconsider scope (retire vs migrate) for low-value interfaces.
