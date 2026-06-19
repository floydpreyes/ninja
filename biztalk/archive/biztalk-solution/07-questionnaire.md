# BizTalk Discovery — Quick SME Interview (≤ 30 min)

Goal: validate how BizTalk is wired today so the AIS migration plan reflects
reality, not assumptions. Twelve questions + a short artefact request.

## How BizTalk is being used today

1. At a high level, what does BizTalk *do* for MW — mostly file movement,
   mostly APIs, or a mix? Roughly what split?

2. For file-based integrations: how does BizTalk pick up files (which folders
   / SFTP), and how does it deliver to the destination (folder drop, API,
   database)? Any naming or archive conventions we should preserve?

3. For API-based integrations: are they mostly SOAP, REST, or both? Is the
   WCF Router (SVBZWEBPROD01/02) the front door for everything external, or
   do some callers hit BizTalk directly?

4. Where do the **transformations** happen — BizTalk Maps, custom .NET helper
   code, Business Rules Engine, or a mix? Any rules you'd flag as complex or
   business-critical?

5. Are any integrations **long-running or stateful** (waiting for callbacks,
   correlating multiple messages), or are they all simple request/response
   and pass-through?

## Operational reality

6. How are credentials and secrets handled today (SSO affiliate apps, config
   files, service accounts)?

7. What does monitoring + alerting look like in practice — BizTalk360
   dashboards, email alerts, on-call run-book? What are the top one or two
   recurring issues?

8. What's the deployment process and release cadence? Anything that makes
   releases slow or risky?

## Things that shape the AIS design

9. Which integrations have the **highest business impact or volume** — the
   ones we cannot afford to get wrong on cutover?

10. Which integrations are the **most fragile or least documented** today
    (original author gone, no tests, "don't touch it")?

11. For external partners (Pega, TechOne, Zycus, Programmed, etc.), are their
    endpoints, IP allow-lists, and contracts likely to stay stable, or are
    any of them changing soon?

12. Anything happening *outside* BizTalk that logically belongs with it —
    scheduled tasks on the servers, SSIS packages, cron jobs, manual file
    moves?

## Validation against AIS design assumptions

13. Do you have BizTalk source code + binding files in source control that we
    can run [aimbiztalk](https://github.com/Azure/aimbiztalk) and [BizTalk
    Documenter](https://github.com/mbrimble/biztalkdocumenter) against?
    *(If yes, we can auto-generate most of the inventory and skip a lot of
    manual interview work.)*

14. Roughly, what's the message throughput and message size profile per
    integration — any over a few thousand/day or above 1 MB?
    *(Key sizing inputs for Logic Apps Standard plan + Service Bus Premium tier.)*

15. Any use of EDI, custom adapters, or custom pipeline components we should
    know about?
    *(EDI and custom adapters are the most common surprises in BizTalk
    migrations — they don't have a 1:1 AIS replacement.)*

## Option to flag at end of session

> "We may also recommend deploying some Logic Apps in a **hybrid (on-prem)
> runtime** during the transition, which keeps traffic on-prem while we wait
> for the cloud security perimeter — would that be acceptable to your
> operations team?"

## Please send us afterwards (whatever's easy to grab)

- BizTalk Admin export of one or two representative applications (binding files)
- BizTalk360 alert list + any dashboards
- Source repo links for the BizTalk projects and any helper assemblies
- Last 12 months of BizTalk-tagged incidents (titles only is fine)

## Worked-example option

Tell us if you'd rather walk through this with one app group as a worked
example (suggest **02-Maximo** or **08-DevConnect**) — sometimes one concrete
walkthrough is faster than answering generally.
