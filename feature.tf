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

  # The co-sell role the agent assumes: consumed (the target account ran
  # namazu-apn-cloudformation and handed over the ARN) or created below.
  cosell_role_arn = coalesce(
    local.apn.consume_role_arn,
    local.apn.create_role ? aws_iam_role.cosell[0].arn : null,
  )

  # Trust principals: the agent pod's own role, plus any additional account
  # roots the tenant wants to be able to assume (the cloudformation default
  # trusts the whole Namazu hosting account; per-role is tighter).
  trusted_principals = concat(
    [var.agent_role_arn],
    [for id in local.apn.trusted_account_ids : "arn:aws:iam::${id}:root"],
  )

  # The trust conditions fold exactly like the template's Fn::If ladder:
  # SourceIdentity always; ExternalId / RoleSessionName pins only when set.
  trust_conditions = merge(
    { "sts:SourceIdentity" = local.apn.source_identity },
    local.apn.external_id != null ? { "sts:ExternalId" = local.apn.external_id } : {},
    local.apn.session_name_pin ? { "sts:RoleSessionName" = "${local.apn.source_identity}-session" } : {},
  )
}

# The outbound assume permission — the tenant-account equivalent of
# namazu-main-aws-terraform's CosellingAgentOutboundAssumption policy, but
# scoped to the ONE role this tenant's agent actually assumes (the hosting
# account's version wildcards the role namespace because the customer
# account varies; here the target is known, so it is exact).
resource "aws_iam_role_policy" "coselling_outbound" {
  count = local.enabled && local.cosell_role_arn != null ? 1 : 0

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
  count = local.enabled && local.apn.ecr_enabled ? 1 : 0

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

# The co-sell role itself, ported from namazu-apn-cloudformation's
# opportunity-manager-role.yaml (trust + AuthorizedUser tag + the
# partnercentral action surface, optional catalog pin). Accountability is
# per named user: the trust policy only accepts sessions presenting the
# AuthorizedUser as sts:SourceIdentity, so every action lands in CloudTrail
# under that identity.
resource "aws_iam_role" "cosell" {
  count = local.enabled && local.apn.create_role && local.apn.source_identity != null ? 1 : 0

  name = local.apn.role_name
  description = join(" ", [
    "Assumed by this tenant's namazu-agent-apn pod (source identity",
    "${local.apn.source_identity}) to manage Partner Central co-selling",
    "opportunities. Created by namazu-cloud-addon-agent-apn.",
  ])

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AgentIdentityEnforcement"
        Effect    = "Allow"
        Principal = { AWS = local.trusted_principals }
        Action = [
          "sts:AssumeRole",
          "sts:SetSourceIdentity",
        ]
        Condition = {
          StringEquals = local.trust_conditions
        }
      },
    ]
  })

  tags = merge(
    local.audit_tags,
    {
      AuthorizedUser = local.apn.source_identity
      ManagedBy      = "namazu-cloud-addon-agent-apn"
    },
  )

  inline_policy {
    name = "PartnerCentralOpportunityManagement"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowPartnerCentralOpportunityManagement"
          Effect = "Allow"
          Action = [
            # The agent's full command surface (verified against the AWS
            # Service Authorization Reference; the IAM action prefix is
            # partnercentral:, distinct from the partnercentral-selling
            # CLI/SDK namespace) — identical to the cloudformation template.
            "partnercentral:CreateOpportunity",
            "partnercentral:UpdateOpportunity",
            "partnercentral:SubmitOpportunity",
            "partnercentral:AssignOpportunity",
            "partnercentral:AssociateOpportunity",
            "partnercentral:DisassociateOpportunity",
            "partnercentral:GetOpportunity",
            "partnercentral:ListOpportunities",
            "partnercentral:ListEngagementInvitations",
            "partnercentral:GetEngagementInvitation",
            "partnercentral:AcceptEngagementInvitation",
            "partnercentral:RejectEngagementInvitation",
            "partnercentral:GetAwsOpportunitySummary",
            "partnercentral:ListSolutions",
            "partnercentral:TagResource",
            "partnercentral:UntagResource",
            "partnercentral:ListTagsForResource",
          ]
          Resource = local.apn.resource_scope
          Condition = local.apn.catalog != null && local.apn.catalog != "" ? {
            StringEquals = { "partnercentral:Catalog" = local.apn.catalog }
          } : null
        },
      ]
    })
  }
}
