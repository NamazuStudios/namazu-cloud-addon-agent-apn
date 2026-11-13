# Running a WAFR

A Well-Architected Framework Review, grounded in the customer's actual
workloads — built by the agent from the evidence you give it.

## What you'll do

Get source material in front of the agent (three ways, below), then ask
it to fill out a WAFR. The agent works through the Well-Architected
pillsars against your evidence and records the review via the AWS
Well-Architected Tool API. A grounded WAFR is the backbone of
Well-Architected funding submissions.

## Before you start

- The deal has a directory (`deals/acme-erp-migration/`) — see
  [Getting started](00-getting-started.md).
- **Operator check:** the agent's IAM policy must grant
  `wellarchitected` permissions in addition to Partner Central. The
  base addon scopes the role to Partner Central only — ask your
  operator to extend the policy (the
  [IAM action inventory](https://servicereference.us-east-1.amazonaws.com/v1/service-list.json)
  lists the exact `wellarchitected` actions). The agent reports
  `AccessDenied` plainly if this is missing.

## Step 1 — get the source material to the agent

Any one of these works; more is better. Put files in the deal's
directory (or `reference/technical/` for material reused across deals).

### Option A — infrastructure as code

Upload the workload's CloudFormation, Terraform, or other IaC into the
deal's directory — or point the agent at the repo:

> Clone github.com/acme/platform-infrastructure into
> deals/acme-erp-migration/ and treat it as the WAFR evidence base.

The agent reads the templates directly: resources, sizes, networking,
encryption, tagging.

### Option B — a resource dump from the AWS account

If the workload is live, a text dump of the actual resources grounds
the review in reality. Generate one from the customer's account with
the AWS CLI — for example:

```sh
aws resourcegroupstaggingapi get-resources --output json > resources.json
aws configservice select-aggregate-resource-config ... # or a Config export
```

Upload the dump into the deal's directory. The agent reads the JSON the
same way it reads IaC. (The agent's own AWS access is Partner
Central-scoped and cannot run these commands against the customer
account — the dump is generated wherever the customer's credentials
work, then uploaded.)

### Option C — architecture documents

Upload architecture diagrams (PDF, PNG), design documents, runbooks.
The agent extracts text with `pdftotext` and reads images directly.

### Then say what it's for

> Everything in deals/acme-erp-migration/evidence/ is the source
> material for the WAFR.

## Step 2 — ask the agent to run the review

> Run a WAFR for the Acme ERP workload. Work through the pillars
> against the evidence, flag high-risk items, and fill out the review.

## What the agent does

The agent reads every file in the evidence set — IaC resources,
resource dumps, architecture text — and builds the workload picture:
what's deployed, how it's secured, how it fails, how it's operated. It
then creates the workload in the AWS Well-Architected Tool via the
`wellarchitected` API, associates the appropriate lenses, and works
through the review questions, answering from the evidence and marking
anything it can't substantiate as an explicit risk rather than
guessing. The result: a review record in AWS, an HR0 in hand, and a
written summary of high-risk items and remediation candidates — saved
into the deal's directory.

What it will not do: invent answers. Where the evidence is silent, the
agent says so and tells you what to ask the customer.

## Tips & troubleshooting

- **Evidence beats recollection.** A Terraform directory the agent
  reads directly produces a defensible review; a paragraph of prose
  produces a generic one. Favor Options A and B.
- **Funding-ready output.** A completed WAFR with identified risks and
  remediation plans is the input POC and MAP submissions want —
  [Generating deliverables](05-deliverables.md) turns it into the
  documents.
- **`AccessDenied` on `wellarchitected`.** The deployment's policy
  doesn't include the service yet — see the operator check above.
- **Per-deal workloads.** One workload per deal in the
  Well-Architected Tool keeps reviews and funding claims aligned; the
  agent names workloads after the deal.
