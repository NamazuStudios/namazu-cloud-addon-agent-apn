# AWS wiring for the co-selling agent (namazu-agent-apn) — the per-tenant
# half of what NamazuStudios/namazu-main-aws-terraform#14 +
# NamazuStudios/namazu-apn-cloudformation do for the hosting account:
#
#   - the OUTBOUND permission on the tenant's agent pod IRSA role
#     (sts:AssumeRole + sts:SetSourceIdentity onto the co-sell role), so the
#     pod can assume a cross-account role and never holds static credentials;
#   - optionally the co-sell role ITSELF (the Namazu-CoSell-Opportunity-
#     Manager shape from namazu-apn-cloudformation's opportunity-manager
#     template: trust pinned to the agent role + a sts:SourceIdentity that
#     must equal the role's AuthorizedUser tag, optional ExternalId /
#     RoleSessionName pins, the partnercentral action surface, optional
#     catalog pin) — for tenants whose account owns the Partner Central
#     relationship;
#   - ECR pull for the agent's own image/chart repositories, on the same
#     agent role (the pod's helm install pulls them under its IRSA identity).
#
# The chart install itself stays manual for now (this is a trial tool,
# installed by hand into a workspace namespace — see README for the exact
# helm command and where this addon's outputs plug in).
#
# The two author rules (contract, stated inline so consumers inherit them):
#  1. NEVER re-declare a variable from 20-variables.tf — those are the
#     tenant contract, not yours. Addon-semantics inputs live in
#     variables.tf and are fed from manifest.yaml's `input` bindings.
#  2. NEVER couple to another addon except through its outputs (via
#     `$addon.<id>.<output>` bindings in manifest.yaml).

locals {

  apn = var.agent_apn

  # Nothing can be wired without the tenant's agent role — the baseline only
  # mints one when bedrock models are enabled, or when the deploy path passes
  # namazu_agent_service_account_role_arn. Absent role ⇒ inert install, not a
  # failed one.
  enabled = local.apn.enabled && var.agent_role_arn != null

  # aws_iam_role_policy takes a role NAME; the baseline hands us the ARN.
  agent_role_name = var.agent_role_arn != null ? element(split("/", var.agent_role_arn), length(split("/", var.agent_role_arn)) - 1) : null

  # The co-sell role the agent assumes is OWNED BY namazu-apn-cloudformation (the
  # account-owner artifact). The addon NEVER creates it — it consumes the
  # ARN the consuming fork supplies. null-safe for inert installs.
  cosell_role_arn = try(local.apn.consume_role_arn, null)
}



# The outbound assume permission — the tenant-account equivalent of
# namazu-main-aws-terraform's CosellingAgentOutboundAssumption policy, but
# scoped to the ONE role this tenant's agent actually assumes (the hosting
# account's version wildcards the role namespace because the customer
# account varies; here the target is known, so it is exact).
#
# Detaches while the tenant is billing-suspended (the baseline folds
# `suspended` into the agent_apn map): a held tenant's identity can assume
# nothing — the same detach-on-hold the baseline applies to the Bedrock
# invocation policy.
resource "aws_iam_role_policy" "coselling_outbound" {
  count = local.enabled && !local.apn.suspended && local.cosell_role_arn != null ? 1 : 0

  name = "CosellingAgentOutboundAssumption"
  role = local.agent_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowOutboundCrossAccountAssumption"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:SetSourceIdentity",
        ]
        Resource = [local.cosell_role_arn]
      },
    ]
  })
}

# ECR pull for the agent's own image + chart repositories, on the agent role
# (the pod's runtime `helm install` authenticates with its IRSA identity;
# kubelet pulls the image under the node role, which the hosting account
# side already covers). Cross-account pull additionally needs the hosting
# account's repository policies to grant this tenant account pull — that is
# the namazu-main-aws-terraform / namazu-cloud-terraform side of the
# go-live checklist, not something this addon can grant from here.
resource "aws_iam_role_policy" "ecr_pull" {
  count = local.enabled && !local.apn.suspended && local.apn.ecr_enabled ? 1 : 0

  name = "CosellingAgentEcrPull"
  role = local.agent_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # No resource-level scoping exists for this action in IAM.
        Sid      = "EcrAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrAgentApnPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages",
        ]
        Resource = [
          "arn:aws:ecr:us-east-1:${local.apn.ecr_registry_account}:repository/namazu-agent-apn",
          "arn:aws:ecr:us-east-1:${local.apn.ecr_registry_account}:repository/namazu-agent-apn-helm",
        ]
      },
    ]
  })
}

