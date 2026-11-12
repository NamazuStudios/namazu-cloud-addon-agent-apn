# Agent integration — what the co-selling agent connects, and why

<div align="center">

**Your APN funding engine, wired into everything the deal touches.**

[![License: AGPL v3](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

</div>

## The selling points

- **Runs the entire Partner Central co-sell motion without touching the APN console** — ACE opportunities authored, updated, and managed end to end.
- **Reviews your evidence like a partner development manager** — infrastructure code, architecture documents, application source — and writes the opportunity up properly.
- **Generates WAFRs grounded in your actual workloads** for funding submissions.
- **Estimates cloud usage and costs** — accurate, defensible numbers for POC, MAP, and every other AWS Partner funding benefit.
- **Tracks deals in Namazu Cloud — multiple at a time** — every opportunity, every stage, nothing falling through.
- **Turns meeting notes into ACE** — call and meeting summaries land straight in the opportunity record.
- **Produces client-ready deliverables** — PDFs, Word documents, pitch decks, and more, generated from the deal record.
- **Optimizes opportunity scores** and provides next steps, sales guidance, and objection analysis continuously.
- **Zero standing risk**: no static credentials, IRSA-only identity, every action attributable in CloudTrail to a named user.

---

## The integration surface

### 1. AWS Partner Central (ACE)

The agent works the
[APN Customer Engagements (ACE) program](https://aws.amazon.com/partners/selling/ace/)
directly: opportunity authoring, stage updates, evidence attachments,
score optimization, and next-step guidance. No console, no export/import
loops.

### 2. Your deal record in Namazu Cloud

Deals live in Namazu Cloud and are tracked **in parallel** — meeting
notes flow in and are summarized into ACE, deliverables render back out
(PDF, Word, pitch decks), and the agent keeps stage, risks, and next
steps current across as many opportunities as you have.

### 3. Your evidence

Point the agent at your **infrastructure code, architecture documents,
and application source**. It reviews what the submission needs and
attaches it: the Well-Architected review
([WAFR](https://aws.amazon.com/well-architected/)), the architecture
summary, the usage and cost model backing your
[POC / MAP funding](https://aws.amazon.com/partners/partner-funding/)
request.

### 4. The deliverables pipeline

Client-ready outputs render from the deal record: PDFs for the customer,
Word documents for the partner manager, pitch decks for the review.

### 5. The AWS security surface (what this addon installs)

This addon is the tenant-account wiring that makes all of the above safe:

- **Outbound assume** — `sts:AssumeRole` + `sts:SetSourceIdentity` on the
  tenant's agent IRSA role, targeting the co-sell role, with a per-user
  source identity so **every action is attributable in CloudTrail**.
- **The optional co-sell role** — `create_role = true` renders a
  `Namazu-CoSell-Opportunity-Manager` role in the tenant account (ported
  1:1 from the paired
  [namazu-apn-cloudformation](https://github.com/NamazuStudios/namazu-apn-cloudformation)
  template), with optional `ExternalId` and session-name pins and catalog
  selection (`Sandbox` for AWS's isolated test catalog, `AWS` for
  production deals). Or consume an existing role by ARN.
- **ECR pull** — the agent's image and chart repositories
  (`namazu-agent-apn`, `namazu-agent-apn-helm`) pull through the same
  agent role. No static credentials anywhere; the agent never holds a
  secret.

The chart install itself stays manual by design — see the main
[README](README.md) for the helm command and the verification steps.
