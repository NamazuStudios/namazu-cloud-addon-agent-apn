# Managing opportunities

Basic agent operations: creating, drafting for review, updating, and
submitting ACE opportunities — by asking.

## What you'll do

Run the day-to-day of Partner Central through conversation. The agent
knows the AWS command surface; you know the deal. You'll describe
reality and let the agent translate it into opportunity records.

## Before you start

- The workspace is set up ([Getting started](00-getting-started.md)).
- Know which catalog you're on. Learn on `Sandbox`; on `AWS` you are
  touching real deals with real AWS review behind them.

## A 60-second model of the record

Two things AWS cares about, worth knowing before you start:

- **Lifecycle stage** — where the deal really is:
  `Prospect` → `Qualified` → `Technical Validation` →
  `Business Validation` → `Committed` → `Launched`, or `Closed Lost`.
  A lead must reach `Qualified` before it can be submitted.
- **Co-sell motion** — AWS assigns one to every submitted opportunity:
  *AWS Field-engaged* (an AWS seller joins; updates pass AWS review),
  *Agent-engaged* or *Partner-led* (updates accepted immediately). The
  motion follows the Opportunity Quality Score — which is why rich
  records matter.

The full business-process detail lives in the [Partner Central Sales
Guide](https://docs.aws.amazon.com/partner-central/latest/sales-guide/)
— the agent consults it; you can too.

## Steps

### Create

Describe the deal the way you'd tell a colleague. The agent asks for
whatever's missing and creates the record:

> Create an opportunity for Acme Corp — ERP migration to AWS, expected
> spend $120k over 8 months. Contact is Jane Okafor, VP Engineering.
> We'd want architectural validation from AWS.

The agent populates what it can, flags what it needs (industry, use
case, delivery model, expected contract duration), and confirms the
record before writing it. It also creates the deal's directory in the
workspace — `deals/acme-erp-migration/` with a `SUMMARY.md` — so
everything about the deal has a home.

### Draft for review

Never submit blind. Ask for a draft and read it as AWS will:

> Draft the Acme opportunity for my review — update everything we know
> from this week and show me what you'd submit before you do.

The agent shows the proposed field changes, tells you which Opportunity
Quality Score components the update strengthens, and waits. You edit
the draft by replying; the agent applies it only when you approve.

### Update

As the deal moves, say what happened:

> The Acme POC went well — they've approved the architecture. Move the
> deal forward and update the record.

The agent updates the lifecycle stage, marks sales activities
completed, refreshes `SUMMARY.md`, and shows you the diff on material
changes.

### Submit

> Submit Acme for co-sell review.

The agent runs the submission and reports the result. After that it
can check the review status on demand:

> Where is Acme in AWS review?

Review status cycles `Pending Submission` → `Submitted` → `In review`
→ `Approved` / `Rejected`. If AWS flags validation issues, the agent
reads them and proposes fixes; you approve, it resubmits.

### AWS referrals

Referrals AWS sends you appear as engagement invitations:

> Any new referrals from AWS? Show me the details of anything pending.

The agent lists and summarizes them; accepting or rejecting is your
call, on its recommendation.

## What the agent does

The agent runs the `partnercentral-selling` API surface —
`list-opportunities`, `get-opportunity`, `create-opportunity`,
`update-opportunity`, `submit-opportunity`, the engagement-invitation
commands, and `get-aws-opportunity-summary` — always under an assumed
role, always with the catalog flag set. It keeps the workspace's
`SUMMARY.md` in step with every change so the file browser always shows
the deal as AWS sees it.

## Tips & troubleshooting

- **Default is co-sell.** The agent submits for AWS review unless you
  say otherwise — it's the standing rule that gets deals funded.
- **Sparse records stall.** Every field you can fill is score
  substance; see [Maximizing the opportunity score](03-opportunity-score.md).
- **`AccessDenied`** means the deployment's IAM policy is narrower than
  the action needs — the agent reports it rather than improvising;
  escalate to your operator.
- **Wrong deal touched?** On `AWS` catalog there is no undo button for
  a submission — that's why drafts are the default. Ask before
  anything that writes.
