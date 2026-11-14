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

  # The cosell chart - installed by the RUNNER's terraform apply (the helm
  # provider ships in the contract's 30-providers.tf, authenticated as the
  # executor role; the OCI pull is why the feature grants carry
  # EcrAuthToken). Registers a PodTemplate conductor discovers and
  # dispatches against - nothing runs until a job is dispatched, so
  # "installed" is safe by construction.
  chart_enabled = (local.enabled
    && !local.apn.suspended
    && local.apn.chart_enabled
    && local.apn.chart_version != ""
    && local.cosell_role_arn != null
  && var.agent_service_account_name != "")
}

resource "helm_release" "cosell" {
  count = local.chart_enabled ? 1 : 0

  name       = "cosell"
  repository = "oci://${local.apn.ecr_registry_account}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/namazu-agent-apn-helm"
  chart      = "namazu-agent-apn-helm"
  version    = local.apn.chart_version
  namespace  = local.addon_namespace
  # The tenant namespace IS the identity: never create another one.
  create_namespace = false
  # NEVER wait: the chart's PVC is WaitForFirstConsumer and nothing runs
  # until a conductor dispatch — helm --wait would block on a PVC that
  # structurally cannot bind until a job schedules it (the 5m deadline
  # failures, 2026-11-13).
  wait          = false
  wait_for_jobs = false
  # 20 min: the provider's exec-plugin auth (`aws eks get-token` per API
  # call, racing on the AWS CLI credential cache under the TWO concurrent
  # workspace applies) crawls — installs observed taking well past the
  # 300s default (the pending-install → context-deadline pattern,
  # 2026-11-13). The chart itself installs in seconds via the plain CLI;
  # the crawl is auth overhead, so give the action room instead of
  # failing at the wall.
  timeout = 1200

  set {
    name  = "aws.enabled"
    value = "true"
  }
  set {
    name  = "aws.roleArn"
    value = local.cosell_role_arn
  }
  set {
    name  = "aws.sourceIdentity"
    value = local.apn.source_identity
  }
  # Charm Hyper (the core chart's agent.hyper.*): the contract decides;
  # the namespace's charm-hyper Secret supplies the key (chart-rendered
  # secretKeyRef — the addon never touches the secret).
  set {
    name  = "agent.hyper.enabled"
    value = local.apn.hyper_enabled ? "true" : "false"
  }
  set {
    name  = "agent.hyper.apiKeySecretName"
    value = local.apn.hyper_api_key_secret_name
  }
  set {
    name  = "agent.hyper.model"
    value = local.apn.hyper_model
  }
  # The picker whitelist as a helm set_list (the chart value is a list;
  # `set` cannot carry one). Omitted when the contract doesn't pin —
  # which renders NO models declaration and leaves every id unavailable
  # to opencode, so real deployments should always pin the verified list.
  dynamic "set_list" {
    for_each = local.apn.hyper_models != null ? [local.apn.hyper_models] : []
    content {
      name  = "agent.hyper.models"
      value = set_list.value
    }
  }
  dynamic "set" {
    for_each = local.apn.external_id != null ? [local.apn.external_id] : []
    content {
      name  = "aws.externalId"
      value = set.value
    }
  }
  dynamic "set" {
    for_each = local.apn.catalog != null ? [local.apn.catalog] : []
    content {
      name  = "aws.catalog"
      value = set.value
    }
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = local.runner_sa_name
  }
  set {
    name  = "serviceAccountName"
    value = local.runner_sa_name
  }

}



# ---- the dedicated runner identity ----------------------------------------
# The pod's ServiceAccount + IAM role: NOTHING but assume the co-sell role
# (the contract's consume_role_arn — same-account or cross-account) and
# pull the agent images. The shared bedrock-irsa workspace role keeps only
# its platform duties; the co-sell grants moved here.
locals {
  runner_sa_name      = "cosell-agent"
  runner_role_name    = "cosell-runner-${local.addon_namespace}"
  cluster_oidc_issuer = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.cluster_oidc_issuer, "https://", "")}"
}

data "aws_caller_identity" "current" {}

# IRSA trust for the runner ServiceAccount (the chart renders it —
# serviceAccount.create=true — in the tenant namespace).
data "aws_iam_policy_document" "runner_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts.amazonaws.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.cluster_oidc_issuer}:sub"
      values   = ["system:serviceaccount:${local.addon_namespace}:${local.runner_sa_name}"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = local.runner_role_name
  assume_role_policy = data.aws_iam_policy_document.runner_trust.json
}

# The outbound assume permission — the tenant-account equivalent of
# namazu-main-aws-terraform's CosellingAgentOutboundAssumption policy, but
# scoped to the ONE role this tenant's agent actually assumes (the hosting
# account's version wildcards the role namespace because the customer
# account varies; here the target is known, so it is exact).
#
# Both policies attach to the DEDICATED runner role (cosell-runner-<ns>),
# NOT the shared bedrock-irsa role: the runner identity can do nothing but
# assume the co-sell role (same- or cross-account) and pull the agent
# images. The shared workspace role keeps its platform duties untouched.
#
# Detaches while the tenant is billing-suspended (the baseline folds
# `suspended` into the agent_apn map): a held tenant's identity can assume
# nothing — the same detach-on-hold the baseline applies to the Bedrock
# invocation policy.
resource "aws_iam_role_policy" "coselling_outbound" {
  count = local.enabled && !local.apn.suspended && local.cosell_role_arn != null ? 1 : 0

  name = "CosellingAgentOutboundAssumption"
  role = aws_iam_role.runner.name

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
  role = aws_iam_role.runner.name

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

