# Tutorials — the AWS co-selling agent

The co-selling agent runs your AWS Partner Central motion from inside
Namazu Cloud: it creates and updates ACE opportunities, turns meeting
notes into deal records, maximizes your Opportunity Quality Score, runs
Well-Architected reviews, and generates client-ready deliverables. You
talk to it; it does the work.

These tutorials teach the motion, not commands. Every example is a
sentence you type to the agent — the agent owns the AWS calls, the file
handling, and the document pipeline.

## The workspace

The agent's workspace is a file tree you can browse and edit directly
in the Namazu Cloud ADE file browser. The agent organizes it the same
way every time:

```
/workspace
├── reference/
│   ├── branding/        # logos, art, style guides, previous proposals
│   └── technical/       # architecture docs, technical documentation
└── deals/
    └── acme-erp-migration/   # one directory per deal
        ├── SUMMARY.md          # the deal's record — kept current
        ├── notes/              # meeting notes, summaries, coaching
        └── deliverables/       # decks, docs, PDFs you can open
```

Drop material into the right directory, ask the agent to work with it,
and open what it produces — all in the browser.

## The tutorials

Read in order — each builds on the workspace the previous one set up:

| # | Tutorial | You learn to... |
|---|----------|-----------------|
| 00 | [Getting started](00-getting-started.md) | Say "help me get started" and get a working workspace |
| 01 | [Managing opportunities](01-manage-opportunities.md) | Create, draft, update, and submit ACE opportunities by asking |
| 02 | [Meeting notes to ACE](02-meeting-notes.md) | Turn uploaded meeting notes into summaries, coaching, and record updates |
| 03 | [Maximizing the opportunity score](03-opportunity-score.md) | Audit an opportunity against AWS's published score components |
| 04 | [Running a WAFR](04-wafr.md) | Turn IaC, resource dumps, and architecture docs into a Well-Architected review |
| 05 | [Generating deliverables](05-deliverables.md) | Produce branded pitches, SOWs, and decks — then edit them in the browser |

## Before you start

- **The addon is installed.** The AWS wiring — outbound-assume
  permission, ECR pull, the co-sell role — is set up per
  [INTEGRATION.md](../INTEGRATION.md). If the agent reports a
  session or permissions problem, it's operator territory, not yours.
- **Know your catalog.** Every Partner Central call runs against
  either `AWS` (production — real deals) or `Sandbox` (isolated fake
  data — safe to learn against). The agent tells you which one it's on
  during onboarding. Learn on Sandbox; be deliberate on `AWS`.
- **Deal data is confidential.** It lives in the deal's directory and
  the deliverables the agent produces — nowhere else.

## The fastest way to learn

Ask the agent. "What can you do with opportunities?", "How would we
raise this score?", "What do you need from me for a WAFR?" — the agent
explains its own motion, and everything it suggests it can do next.
