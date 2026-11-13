# Addon-owned inputs — fed from this repo's manifest.yaml `input` bindings.
# Contract variables (instance_id, organization_id, ...) are NOT declared here
# and never will be: see 20-variables.tf and author rule 1 in feature.tf.
#
# As with namazu-cloud-addon-gpu, the per-tenant knobs live in ONE object so
# the manifest binds the tenant baseline's whole `addon_agent_apn` output in
# a single `$instance.` ref. Defaults are fully inert (enabled = false): an
# accidental install wires nothing.

variable "agent_apn" {
  description = "Per-tenant co-selling agent (namazu-agent-apn) AWS wiring. enabled=false creates nothing. consume_role_arn points at the co-sell role in the target account - created from NamazuStudios/namazu-apn-cloudformation by whoever owns that account. The addon NEVER creates the role (the account-wide name collision just proved why): it attaches the outbound-assume + ECR policies to the tenant's agent role and installs the chart. source_identity is the sts:SourceIdentity every assume must present (it must equal the role's AuthorizedUser tag — that match is what makes every action attributable in CloudTrail). external_id is optional additional confused-deputy protection (sts:ExternalId pin). catalog pins the role's partnercentral permission policy to one Partner Central catalog (Sandbox = AWS's isolated test catalog, AWS = production deals); empty = no pin."
  type = object({
    enabled              = bool
    consume_role_arn     = optional(string)
    source_identity      = optional(string)
    external_id          = optional(string)
    catalog              = optional(string)
    resource_scope       = optional(string, "*")
    ecr_enabled          = optional(bool, true)
    ecr_registry_account = optional(string, "308044622771")

    # The chart install (terraform-managed): when the addon is enabled and
    # chart_version is set, the runner's terraform apply installs the cosell
    # chart into the tenant namespace via the helm provider (executor
    # identity; OCI pull from the ECR chart repo).
    chart_enabled = optional(bool, true)
    chart_version = optional(string, "")

    # Set by the tenant baseline from its billing_suspended input (the
    # zero-compute billing hold, namazu-cloud-instance PR #89) — not a
    # tenant tfvars knob. While true the OUTBOUND and ECR policies detach
    # from the agent role (the same detach-on-hold pattern the baseline
    # applies to the Bedrock invocation policy) so a held tenant's identity
    # can assume nothing; the co-sell role itself survives (its ARN is
    # handed to the chart and must stay stable across a hold).
    suspended = optional(bool, false)
  })

  default = {
    enabled = false
  }
}

variable "agent_service_account_name" {
  description = "The tenant's generated namazu-agent ServiceAccount name (namazu-agent-<suffix>) - a generic platform fact the baseline OUTPUTS (namazu_agent_service_account_name). The cosell chart's serviceAccountName: the pod identity that assumes the co-sell role."
  type        = string
  default     = ""
}

variable "agent_role_arn" {
  description = "The tenant's namazu-agent pod IRSA role (the baseline's effective agent role: the per-tenant Bedrock role when bedrock models are enabled, else the deploy path's namazu_agent_service_account_role_arn). The outbound assume permission and ECR pull attach here. Null when the tenant has neither — the addon stays inert. Bound from the tenant baseline: $instance.namazu_agent_service_account_role_arn."
  type        = string
  default     = null
}
