# namazu-cloud-addon-agent-apn

AWS wiring for the **co-selling agent**
([namazu-agent-apn](https://github.com/NamazuStudios/namazu-agent-apn) —
the AWS Partner Central assistant), as a per-tenant addon. It is the
tenant-account half of what
[namazu-main-aws-terraform#14](https://github.com/NamazuStudios/namazu-main-aws-terraform/issues/14)
and
[namazu-apn-cloudformation](https://github.com/NamazuStudios/namazu-apn-cloudformation)
do for the hosting account:

1. **The outbound assume permission** — `sts:AssumeRole` +
   `sts:SetSourceIdentity` on the co-sell role, attached to the tenant's
   agent pod IRSA role (the baseline's effective agent role). The agent
   never holds static AWS credentials; it assumes its target role with its
   ambient cluster identity, presenting a per-user `sts:SourceIdentity`
   that must match the role's `AuthorizedUser` tag — that match is what
   makes every action attributable in CloudTrail.
2. **Optionally the co-sell role itself** (`create_role = true`), ported
   1:1 from `namazu-apn-cloudformation`'s `opportunity-manager-role.yaml`:
   trust pinned to the agent role (+ optional account roots), the
   `partnercentral:*` action surface, optional `ExternalId` /
   `RoleSessionName` pins and catalog pin (`Sandbox` = AWS's isolated test
   catalog, `AWS` = production deals). Use this when the tenant's own
   account owns the Partner Central relationship; otherwise the account
   owner runs the cloudformation template and the tenant consumes the ARN
   (`consume_role_arn`).
3. **ECR pull** for the agent's image/chart repositories
   (`namazu-agent-apn`, `namazu-agent-apn-helm`) on the same agent role —
   the pod's runtime `helm install` authenticates with its IRSA identity.
   Cross-account pull also needs the hosting account's repository policies
   to grant the tenant account pull (the go-live checklist's
   namazu-main-aws-terraform / namazu-cloud-terraform side — not grantable
   from here).

One repo = one addon = one Terraform root (contract:
[`tenant-addons-plan.md`](https://github.com/NamazuStudios/namazu-cloud-instance/blob/main/tenant-addons-plan.md)).
Inert by design: no CI, no bootstrap, no AWS role. `enabled = false`
(the default) creates nothing.

## What it reads (manifest.yaml bindings)

| Variable | Binding | Meaning |
|---|---|---|
| `agent_role_arn` | `$instance.namazu_agent_service_account_role_arn` | the tenant's effective agent IRSA role (Bedrock role when bedrock models are on, else the deploy path's); null ⇒ inert |
| `agent_service_account_name` | `$instance.namazu_agent_service_account_name` | documented wiring for the chart install |
| `agent_namespace` | `$instance.namazu_agent_service_account_namespace` | where the chart installs (identity = tenant = namespace) |
| `agent_apn` | `$instance.addon_agent_apn` | the whole per-tenant config (below) |

All four come from **tenant baseline outputs** — the PR to
`namazu-cloud-instance` adds them to the `per_tenant/aws/*` roots. Until a
tenant's baseline is re-applied with those outputs, installing this addon
for it fails loudly naming the missing output.

## The `agent_apn` input (per-tenant config)

```hcl
addon_agent_apn = {
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

## The chart install (manual, by design)

The agent image + chart publish to their own ECR repos; the chart registers
a PodTemplate conductor discovers and dispatches against — nothing runs
until a job is dispatched. Install into the workspace namespace using this
addon's outputs:

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
      "Resource": ["arn:aws:iam::<account>:role/Namazu-CoSell-Opportunity-Manager*"] }
  ]
}
```

(Drop the `CosellRoleCreate` statement when the tenant only consumes an
existing role. `ecr:GetAuthorizationToken` is required by the contract
`30-providers.tf` itself — its helm ECR registry block does a plan-time
token fetch.)

`bootstrap/rbac.yaml` — no additions beyond the template's default
cluster-role: this addon creates IAM objects only.

## License

MIT — see [LICENSE](LICENSE).
