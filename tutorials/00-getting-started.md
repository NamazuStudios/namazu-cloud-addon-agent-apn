# Getting started

The onboarding is a single sentence.

## What you'll do

Open the agent and ask it to set itself up. The agent builds the
workspace directory structure, fills it with sample content that shows
you what good looks like, verifies its AWS session, and tells you
exactly what it created.

## Before you start

- The addon is installed and the agent is running (see
  [INTEGRATION.md](../INTEGRATION.md)).
- That's it.

## Steps

1. **Open the agent chat** and send:

   > Help me get started.

2. **The agent runs its onboarding sequence:**
   - Creates `reference/branding/` and `reference/technical/` with
     placeholder content, and a sample deal under `deals/` with a
     filled-in `SUMMARY.md` — telling you what it made and where.
   - Verifies its AWS session (`aws sts get-caller-identity`) and
     reports which catalog it's on: `Sandbox` (safe fake data) or `AWS`
     (production).
   - Gives you a one-line tour: the file browser for the workspace,
     chat for everything else.

3. **Look around.** Open the workspace in the ADE file browser. Open
   the sample `SUMMARY.md` — it's the shape the agent keeps for every
   deal: customer, project narrative, financials, co-sell ask,
   activities, stage, review status.

4. **Make it yours.** When your real branding material is ready, drop
   it into `reference/branding/` (logos, style guides, a previous
   proposal or two). Architecture documents go into
   `reference/technical/`. Tell the agent when you've added things —
   it reads what you place there.

5. **Try a first ask.** Something small and read-only:

   > What opportunities do we have in the pipeline right now?

   On the Sandbox catalog, the agent walks through the sample data —
   a safe way to see the motion.

## What the agent does

Under the hood, onboarding is: create the directory tree with sample
content, verify the assumed role and source identity, and report the
catalog. No static credentials are involved anywhere — the agent
assume-roles through the deployment's IAM wiring every session.

## Where to next

- [Managing opportunities](01-manage-opportunities.md) — create and
  submit your first real opportunity
- [Meeting notes to ACE](02-meeting-notes.md) — the fastest way to put
  the agent to work on a live deal

## Troubleshooting

- **"The AWS session failed."** The wiring comes from the deployment —
  role ARN, external ID, source identity. The agent reports what it
  saw; pass it to your operator.
- **On the `AWS` catalog already?** Onboarding never creates or changes
  opportunities — only directories and reads. It's safe anywhere.
