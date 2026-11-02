# Addon-owned inputs — fed from this repo's manifest.yaml `input` bindings.
# Contract variables (instance_id, organization_id, ...) are NOT declared here
# and never will be: see 20-variables.tf and author rule 1 in feature.tf.
#
# As with namazu-cloud-addon-gpu, the per-tenant knobs live in ONE object so
# the manifest binds the tenant baseline's whole `addon_agent_apn` output in
# a single `$instance.` ref. Defaults are fully inert (enabled = false): an
# accidental install wires nothing.

variable "agent_apn" {
  description = "Per-tenant co-selling agent (namazu-agent-apn) AWS wiring. enabled=false creates nothing. consume_role_arn points at a role that already exists in the target account (created from NamazuStudios/namazu-apn-cloudformation by whoever owns that account); create_role=true instead creates the Namazu-CoSell-Opportunity-Manager role HERE from the same template's shape. source_identity is the sts:SourceIdentity every assume must present (it must equal the role's AuthorizedUser tag — that match is what makes every action attributable in CloudTrail). external_id is optional additional confused-deputy protection (sts:ExternalId pin). catalog pins the role's partnercentral permission policy to one Partner Central catalog (Sandbox = AWS's isolated test catalog, AWS = production deals); empty = no pin."
  type = object({
    enabled              = bool
    create_role          = optional(bool, false)
    consume_role_arn     = optional(string)
    role_name            = optional(string, "Namazu-CoSell-Opportunity-Manager")
    source_identity      = optional(string)
    external_id          = optional(string)
    session_name_pin     = optional(bool, false)
    catalog              = optional(string)
    resource_scope       = optional(string, "*")
    trusted_account_ids  = optional(list(string), [])
    ecr_enabled          = optional(bool, true)
    ecr_registry_account = optional(string, "308044622771")
  })

  default = {
    enabled = false
  }
}

variable "agent_role_arn" {
  description = "The tenant's namazu-agent pod IRSA role (the baseline's effective agent role: the per-tenant Bedrock role when bedrock models are enabled, else the deploy path's namazu_agent_service_account_role_arn). The outbound assume permission and ECR pull attach here. Null when the tenant has neither — the addon stays inert. Bound from the tenant baseline: $instance.namazu_agent_service_account_role_arn."
  type        = string
  default     = null
}

variable "agent_service_account_name" {
  description = "The tenant's agent ServiceAccount name (documented wiring for the chart install; see README). Bound from the tenant baseline: $instance.namazu_agent_service_account_name."
  type        = string
  default     = null
}

variable "agent_namespace" {
  description = "The tenant's agent namespace (documented wiring for the chart install; see README). Bound from the tenant baseline: $instance.namazu_agent_service_account_namespace."
  type        = string
  default     = null
}
