# Agent integration — the plumbing and wiring

> The pitch — what the co-selling agent does and why teams run it — lives
> in the [README](README.md). This document is the plumbing: what this
> addon installs, what it reads, and what the consuming org fork needs.

## What this addon installs (per tenant)

Three pieces of tenant-account wiring, all least-privilege, no static
credentials anywhere:

1. **The outbound assume permission** — `sts:AssumeRole` +
   `sts:SetSourceIdentity` on the tenant's agent IRSA role, targeting the
   co-sell role, with a per-user source identity so **every action is
   attributable in CloudTrail**.
2. **The optional co-sell role** — `create_role = true` renders a
   `Namazu-CoSell-Opportunity-Manager` role in the tenant account (ported
   1:1 from the paired
   [namazu-apn-cloudformation](https://github.com/NamazuStudios/namazu-apn-cloudformation)
   template), with optional `ExternalId` and session-name pins and catalog
   selection (`Sandbox` for AWS's isolated test catalog, `AWS` for
   production deals). Or consume an existing role by ARN
   (`consume_role_arn`).
3. **ECR pull** — the agent's image and chart repositories
   (`namazu-agent-apn`, `namazu-agent-apn-helm`) pull through the same
   agent role.

## What it reads (manifest.yaml bindings)

| Variable | Source | Meaning |
|---|---|---|
| `agent_role_arn` | `$instance.namazu_agent_service_account_role_arn` | the tenant's effective agent IRSA role (Bedrock role when bedrock models are on, else the deploy path's); null ⇒ inert |
| `agent_apn` | fork matrix `--contract agent_apn='{...}'` | the whole per-tenant config (below) |

`agent_role_arn` reads a **tenant baseline output** — a generic platform
fact that exists regardless of this addon. The `agent_apn` config
deliberately does NOT flow through the baseline anymore:
namazu-cloud-instance#130 removed the `addon_agent_apn` variable/output
entirely — the consuming org fork's `sync.yml` matrix entry is the request
AND the config, delivered through the runner's `contract` action input.

The agent ServiceAccount name is **generated** (`namazu-agent-<random
suffix>` — `modules/namazu_agent` uses `generate_name`), so it is not a
binding: read it from the tenant namespace (`kubectl get sa -n <tenant>`)
when installing the chart. The chart's namespace is the tenant namespace
itself (identity = tenant = namespace — this addon's `agent_namespace`
output).

## The `agent_apn` input (per-tenant config, via `--contract`)

```hcl
agent_apn = {
  enabled             = true
  create_role         = true                  # or consume_role_arn = "arn:..."
  role_name           = "Namazu-CoSell-Opportunity-Manager"
  source_identity     = "peter"               # = the role's AuthorizedUser
  external_id         = null                  # optional extra pin
  session_name_pin    = false                 # strict "<user>-session" pin
  catalog             = "Sandbox"             # Sandbox | AWS | null
  resource_scope      = "*"
  trusted_account_ids = []                    # extra account-root principals
  ecr_enabled         = true
  ecr_registry_account = "308044622771"
}
```

## Account-wide names — the org qualification rule

IAM role names and the co-sell role are **account-wide** (IAM ARNs are
global), and the shared hosting account hosts every org. Where this addon
creates a NAMED IAM object, the name must be org-distinct:

- `role_name` (the optional in-account co-sell role): the default matches
  namazu-apn-cloudformation's template name — only ONE org per account can
  use the default. Orgs sharing the account MUST set an org-distinct
  `role_name` via `--contract` (e.g.
  `role_name='Namazu-CoSell-Opportunity-Manager-<org-slug>'`), and the
  consuming fork's `CosellRoleCreate` grant must scope to that name. The
  outbound-assume path needs no qualification — that role is the tenant's
  own, named by the baseline.
- ECR pull: scoped to the org-namespaced repositories (`<org-id>/...`) —
  nothing account-wide.

## The chart install (manual, by design)

The agent image + chart publish to their own ECR repos; the chart
registers a PodTemplate conductor discovers and dispatches against —
nothing runs until a job is dispatched. Install into the workspace
namespace using this addon's outputs:

```bash
terraform output -raw cosell_role_arn     # → aws.roleArn
terraform output -raw source_identity     # → aws.sourceIdentity
terraform output -raw external_id         # → aws.externalId (when set)

helm install cosell \
  oci://308044622771.dkr.ecr.us-east-1.amazonaws.com/namazu-agent-apn-helm/namazu-agent-apn-helm \
  --version "0.1.0-<sha>" \
  --namespace <agent_namespace output> \
  --set aws.enabled=true \
  --set aws.roleArn="..." --set aws.externalId="..." \
  --set aws.sourceIdentity="..." --set aws.catalog=Sandbox \
  --set serviceAccountName="<agent_service_account_name output>"
```

Verify by exec'ing in and running `aws sts get-caller-identity` — it must
show the assumed co-sell role ARN and the source identity.

## What the consuming org fork needs

`iam.policy.json` (feature grants, merged onto the executor role by the
fork's `bootstrap/`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "EcrAuthToken", "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"], "Resource": "*" },
    { "Sid": "AgentRolePolicyWrite", "Effect": "Allow",
      "Action": ["iam:GetRole", "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy"],
      "Resource": ["arn:aws:iam::<account>:role/<agent role name>"] },
    { "Sid": "CosellRoleCreate", "Effect": "Allow",
      "Action": ["iam:CreateRole", "iam:DeleteRole", "iam:TagRole", "iam:UntagRole",
                 "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy", "iam:GetRole"],
      "Resource": ["arn:aws:iam::<account>:role/<org-distinct co-sell role name>*"] }
  ]
}
```

(Drop the `CosellRoleCreate` statement when the tenant only consumes an
existing role. Scope the co-sell role pattern to the org-distinct
`role_name` — IAM ARNs are global and the shared account hosts every org.
`ecr:GetAuthorizationToken` is required by the contract
`30-providers.tf` itself — its helm ECR registry block does a plan-time
token fetch.)

`bootstrap/rbac.yaml` — no additions beyond the template's default
cluster-role: this addon creates IAM objects only.

## License & provenance

**AGPL-3.0** — see [LICENSE](LICENSE). This is an **official Namazu Cloud
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
