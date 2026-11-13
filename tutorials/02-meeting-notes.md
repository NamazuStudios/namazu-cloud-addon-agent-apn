# Meeting notes to ACE

Every call produces notes; the agent turns them into deal progress.

## What you'll do

Upload your note-taker's output into the deal's directory, have the
agent parse and summarize it, and let it keep the deal record current —
the ACE opportunity, the workspace `SUMMARY.md`, and the coaching view
all move together.

## Before you start

- The workspace is set up ([Getting started](00-getting-started.md)),
  and a deal directory exists (creating an opportunity makes one — see
  [Managing opportunities](01-manage-opportunities.md)).
- Meeting notes in any text-ish format work: markdown, plain text,
  Word, PDF. The agent reads them all.

## Steps

### 1. Create the deal's notes directory

In the ADE file browser, make a `notes/` directory inside the deal's
folder — `deals/acme-erp-migration/notes/`. One directory per deal is
the convention the agent maintains; everything about this deal lives
under its directory.

### 2. Upload the notes

Upload the notes from your note-taker into that directory — drag and
drop in the file browser. Filenames with dates keep things ordered
(`2026-11-12-kickoff.md`, `2026-11-19-technical-review.docx`).

### 3. Ask the agent to parse and summarize

> Parse the meeting notes in deals/acme-erp-migration/notes and
> summarize the kickoff call.

The agent reads the file and produces:

- **A dated summary** alongside the notes —
  `notes/2026-11-12-kickoff-summary.md` — with what was discussed,
  decisions made, risks raised, and action items.
- **A `SUMMARY.md` refresh** — the deal's record updates with anything
  that changed: stakeholders, requirements, timeline.
- **An opportunity update proposal** — lifecycle stage and sales
  activities that the notes suggest, submitted to you before the agent
  touches the ACE record.

The agent asks when the notes imply material changes ("the notes say
they signed the SOW — move Acme to `Committed` and mark the activity
complete?"). You confirm; it updates the opportunity.

### 4. Get the coaching view

> Coach me on Acme after this meeting.

From the notes and the deal record the agent gives you:

- **Objections actually raised** — pulled from the notes, verbatim.
- **Anticipated objections** — what this customer is likely to raise
  next, given industry and deal shape.
- **Progression tracking** — where the deal sits against the lifecycle
  stages and sales activities, and what's genuinely still open.

Each new set of notes refreshes the coaching — an update, not a
rewrite, so you can see how the deal's story evolved.

### 5. Keep feeding it

Every subsequent call, repeat steps 2–4. The chain — notes → summary →
`SUMMARY.md` → opportunity — stays in step, and the deal's directory
becomes the full narrative of the engagement.

## What the agent does

The agent reads the uploaded files directly from the workspace, writes
the summary and coaching as markdown beside the notes, and carries
confirmed changes into the opportunity via `update-opportunity` —
always with the catalog flag, always through the assumed role. Nothing
you upload leaves the workspace.

## Tips & troubleshooting

- **One directory per deal.** If the notes landed in the wrong place,
  just say so — "move those notes into the Acme deal directory" — and
  the agent tidies up.
- **Pasted notes work too.** Drop them in chat and ask the agent to
  file them in the right deal directory.
- **Sensitive calls.** If a meeting shouldn't reach the ACE record,
  say so explicitly: "summarize these but don't touch the opportunity."
  The agent summarizes locally and skips the record update.
