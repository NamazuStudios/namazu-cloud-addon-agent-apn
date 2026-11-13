# Generating deliverables

Pitches, statements of work, proposals — generated from the deal
record, in your branding, as PDF, Word, or PowerPoint.

## What you'll do

Give the agent your company's branding material once, then ask for
client-ready documents per deal. The agent generates the files into the
deal's directory; you open them in the file browser and edit directly.

## Before you start

- The workspace is set up ([Getting started](00-getting-started.md)).
- Deal directories exist and carry real content — `SUMMARY.md`,
  meeting-note summaries, maybe a WAFR. Deliverables are generated
  *from* the deal record, so a fed record produces a real document.

## Step 1 — load the branding directory

Put your company's material into `reference/branding/` via the file
browser:

- **Logo and art assets** — SVG or PNG; the agent can convert and
  resize as needed.
- **Style guide** — colors, fonts, tone rules, one page is enough.
- **Previous proposals** — the best reference material there is. The
  agent reads them for structure, tone, and level of detail, and
  matches the house style.

Tell the agent once:

> We've loaded our branding into reference/branding. Use it for
> everything client-facing going forward.

## Step 2 — keep work organized per deal

Everything a deliverable needs lives in the deal's directory:
`deals/acme-erp-migration/` — the `SUMMARY.md` record, notes, evidence,
and (soon) the outputs. Organized by deal, nothing cross-contaminates.

## Step 3 — ask for the document

> Generate a pitch deck for the Acme deal — use our branding, draw
> from the SUMMARY and the kickoff notes. PPTX and a PDF copy.

> Draft a statement of work for Acme covering the migration phases,
> based on the WAFR remediation plan. Word format.

The agent writes the content from the deal record, applies the branding
(styles, logo, colors), and drops the finished files into the deal's
directory — e.g. `deals/acme-erp-migration/deliverables/`. It rings the
bell and hands you the path.

## Step 4 — edit the results right there

Open the file browser, click the file, edit. PPTX and DOCX edit in the
browser view; ask the agent for changes too:

> Regenerate the deck without the pricing slide, and tighten the
> timeline section.

The agent regenerates — the deal record stays the source, so the next
generation picks up everything you've corrected in the record.

## What the agent does

The full document pipeline is installed in the agent:

- **PowerPoint**: markdown → `pandoc` → `.pptx`, or `python-pptx` for
  full control on your template deck — plus speaker notes, tables, and
  charts.
- **Word**: markdown → `pandoc` → `.docx` (your corporate template via
  `--reference-doc`), or `python-docx` for structure-heavy documents.
- **PDF**: LibreOffice headless or WeasyPrint for cleanly styled
  output; `qpdf`/Ghostscript for merging and compressing.
- **Charts and art**: matplotlib, graphviz, gnuplot render the numbers
  behind the deck; ImageMagick and `rsvg-convert` process your brand
  assets.

Fonts are metric-compatible with Arial, Times New Roman, and Courier
New, so documents render professionally on any machine.

## Tips & troubleshooting

- **Previous proposals are the style guide.** If the tone of the first
  generation isn't right, add one of your best past documents to
  `reference/branding/` and say "match this."
- **Numbers from the record, not memory.** If a figure in the document
  looks wrong, fix it in `SUMMARY.md` or the opportunity and regenerate
  — the document is downstream of the record.
- **Register the deliverable.** Tell the agent when a document was
  sent: "the SOW went to Acme today" — it notes it in the deal record
  for the AWS submission trail.
