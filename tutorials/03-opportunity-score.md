# Maximizing the opportunity score

AWS scores every submitted opportunity. Ask the agent to make the score
as high as the deal can honestly carry.

## What you'll do

Have the agent audit an opportunity against AWS's published scoring
components, recommend the concrete additions that raise it, and apply
them with your approval.

## Before you start

- The opportunity exists (see
  [Managing opportunities](01-manage-opportunities.md)).
- Scores are earned by completeness, not wording — the agent's job is
  to find what's missing and help you fill it truthfully.

## What AWS actually scores

Every opportunity gets an **Opportunity Quality Score** on submission
and a rescore on every update. It has four published components:

| Component | Weight | What it means |
|-----------|--------|---------------|
| Customer Business Problem Completeness | **Primary driver** | How completely the customer's problem is described — business problem, use case, customer context |
| Next Steps | Significant | Concrete, dated next actions on the deal |
| Partner Primary Need from AWS | Significant | Which co-sell support you're asking for — architectural validation, business presentation, pricing assistance, deal support, and so on |
| Solution and AWS Products | Significant | The solution attached and the AWS services involved |

Alongside the score, AWS weighs strategic importance to assign the
**co-sell motion**: *AWS Field-engaged*, *Agent-engaged*, or
*Partner-led*. Higher scores push toward AWS Field engagement, where an
AWS seller actively joins the deal. Source: the [Agentic Co-sell
engagement](https://docs.aws.amazon.com/partner-central/latest/sales-guide/co-sell-engagement.html)
chapter of the Partner Central Sales Guide.

## Steps

### 1. Ask for the audit

> Audit the Acme opportunity against the four score components. What
> would you add, field by field, to raise the score?

### 2. Read the recommendations

The agent works through the record component by component and reports
gaps in plain terms:

- *"Business Problem Completeness is thin — the use case is 'ERP
  migration' but there's no description of the business driver or the
  customer's decision criteria. This is the primary scoring driver."*
- *"No Next Steps with dates — AWS reads vague next steps as a stalled
  deal."*
- *"Primary Need from AWS is set to a generic value — 'architectural
  validation' would score better and matches what you actually want."*
- *"No solution attached — I can list your registered solutions and
  attach the right one."*

### 3. Fill the gaps with substance

Some gaps the agent fills from material you already have:

> Everything about the business problem is in the kickoff notes in
> deals/acme-erp-migration/notes — pull it from there.

> Set next steps to: POC report delivery Friday, architecture review
> with their infra team on the 24th.

Others need a decision from you. The agent drafts, you approve; it
updates the record and tells you what changed.

### 4. Iterate on updates

AWS rescores on every update, so the loop is cheap:

> What else can we add? Keep going until the only gaps are things we
> genuinely don't know.

Once the score is where the deal can carry it, the residual gaps
themselves are useful — they're the questions to ask the customer on
the next call.

### 5. Feed the loop

New meeting notes change the score's inputs. After the agent
summarizes a call (see [Meeting notes to ACE](02-meeting-notes.md)),
ask it to re-audit — deals that get rescored upward right after each
customer conversation stay healthy in AWS's view.

## What the agent does

The agent reads the opportunity with `get-opportunity`, audits it
against the four published components, drafts the enriching
`update-opportunity` payload, and applies it on your approval — showing
you the before/after. For business-rule questions it consults the
Partner Central Sales Guide documentation directly rather than
guessing.

## Tips & troubleshooting

- **Business Problem Completeness first.** It's the primary driver — a
  complete problem statement moves the score more than any other fix.
- **Honesty is strategy.** AWS validates submissions; an inflated
  record that fails review is worse than a truthful one that passes.
- **Sandbox first.** Practice the audit-and-enrich loop on fake data
  before running it on a live deal.
- **Score doesn't move?** Confirm the update actually landed
  (`get-opportunity`), and check whether AWS's rescore lags — it
  refreshes on update, not instantly.
