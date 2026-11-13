<p align="center">
  <a href="tutorials/README.md"><img src="agent-apn.png" alt="AWS Partner"></a>
</p>

# Namazu APN Agent

**Your APN funding engine.** The co-selling agent runs your entire AWS
Partner Central motion — from first touchpoint to proposal draft.

## What the co-selling agent does

- **Authors and manages every APN ACE Opportunity end to end** — no direct
  APN access required, no tab-switching, no console gymnastics. It works
  the [APN Customer Engagements (ACE) program](https://aws.amazon.com/partners/selling/ace/)
  directly, at every stage, for every deal.
- **Reviews your evidence like a partner development manager**:
  infrastructure code, architecture documents, application source code —
  then writes the opportunity up properly.
- **Generates WAFRs for funding submissions** — Well-Architected reviews
  grounded in your actual workloads, aligned to the
  [AWS Well-Architected Framework](https://aws.amazon.com/well-architected/),
  not filled in from a template.
- **Estimates cloud usage and costs** for accurate, defensible
  [AWS Partner funding](https://aws.amazon.com/partners/partner-funding/)
  submissions — **POC, MAP, and every other funding benefit**.
- **Tracks deals in [Namazu Cloud](https://cloud.namazustudios.com) — multiple at a time** — every
  opportunity, every stage, one dashboard, nothing falling through.
- **Turns meeting notes into ACE** — call and meeting notes summarized
  straight into the opportunity record.
- **Produces the deliverables**: PDFs, Word documents, pitch decks, and
  more — client-ready, generated from the deal record.

And beyond the paperwork: it **optimizes opportunity scores**, recommends
**next steps**, provides **sales guidance**, runs **objection analysis**,
and much more. Your partner development manager that never sleeps.

## Why teams run it

- **Hours become minutes.** An ACE opportunity update — notes summarized,
  evidence reviewed, fields completed, deliverables attached — used to eat
  an afternoon. The agent turns it into a prompt and a review.
- **Submissions that survive scrutiny.** The cost and usage models are
  built from your real workloads and architecture, so POC and MAP
  requests land with defensible numbers instead of optimistic guesses —
  and defensible submissions get approved.
- **Nothing falls through.** Deals are tracked in [Namazu Cloud](https://cloud.namazustudios.com), in
  parallel, with next-step recommendations and objection analysis running
  continuously — not on the whiteboard after the call.
- **Every artifact is client-ready.** The WAFR, the cost model, the pitch
  deck, the Word doc — generated from the deal record, formatted for the
  customer, archived in the opportunity.
- **Auditability is absolute.** Every agent action is attributable in
  CloudTrail to a named user via source identity. Your AWS partner
  manager can trust every line.

## From meeting to funded, in one flow

1. **The call ends.** Drop the meeting notes into the deal record.
2. **The agent summarizes into ACE** — stage, next steps, risks — and
   updates the opportunity score.
3. **Evidence goes in.** Point it at your IaC, architecture docs, and
   source; it reviews and attaches what the submission needs.
4. **The WAFR and cost model generate** — grounded in the actual
   workloads, sized for the POC or MAP benefit you're claiming.
5. **The deliverables render** — PDF for the customer, Word for the
   partner manager, deck for the review.
6. **You submit.** The agent tracks the funding request through its
   lifecycle while it lines up the next opportunity.

That's the motion. The agent runs it as many times in parallel as you
have deals.

## Tutorials

Step-by-step use cases, each built on example prompts you send the
agent: [getting started](tutorials/00-getting-started.md),
[managing opportunities](tutorials/01-manage-opportunities.md),
[meeting notes to ACE](tutorials/02-meeting-notes.md),
[maximizing the opportunity score](tutorials/03-opportunity-score.md),
[running a WAFR](tutorials/04-wafr.md), and
[generating deliverables](tutorials/05-deliverables.md) — or start at
the [tutorials overview](tutorials/README.md).

## The wiring

The AWS plumbing that makes all of this safe — the outbound-assume
permission, the optional co-sell role, ECR pull, the tenant inputs, the
fork's IAM grants, and the chart install — is documented step by step in
**[INTEGRATION.md](INTEGRATION.md)**. Trust is built in: no static
credentials, IRSA-only identity, and every action attributable in
CloudTrail to a named user.

## License & provenance

**AGPL-3.0** — see [LICENSE](LICENSE). This is an **official [Namazu Cloud](https://cloud.namazustudios.com)
addon** — it can be activated for a **fixed fee**; Namazu Studios can also
author a custom addon for a fee scoped to the work required. The
repository is made public for **transparency and visibility**; derivative
works are expected to come back upstream to `NamazuStudios`, no
exceptions.

## AGPL waiver for delivered work

Namazu Studios, as the copyright holder, **waives all AGPL obligations for
software installed through a purchase or other business arrangement
between Namazu Studios and the client.** The AGPL terms above govern the
code as published in this repository; work delivered to you under
contract is delivered under that agreement, not under the license's
reciprocity terms.
