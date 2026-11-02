# What other addons (and operators) can wire against. `$addon.agent-apn.<out>`
# resolves from this addon's statefile per tenant.

output "cosell_role_arn" {
  description = "The role the tenant's co-selling agent assumes (created here, or the consumed namazu-apn-cloudformation role). This is the chart's aws.roleArn value."
  value       = local.enabled ? local.cosell_role_arn : null
}

output "source_identity" {
  description = "The sts:SourceIdentity the agent presents when assuming (the role's AuthorizedUser). This is the chart's aws.sourceIdentity value."
  value       = local.enabled ? local.apn.source_identity : null
}

output "external_id" {
  description = "The sts:ExternalId the agent presents when assuming, when one is configured. This is the chart's aws.externalId value (unset when null)."
  value       = local.enabled ? local.apn.external_id : null
}

output "outbound_policy_role" {
  description = "The agent IRSA role the outbound assume + ECR permissions were attached to (by name, for audit/inspection)."
  value       = local.enabled ? local.agent_role_name : null
}

output "agent_namespace" {
  description = "The tenant's agent namespace — where the cosell chart installs (identity = tenant = namespace; this addon's own namespace)."
  value       = local.addon_namespace
}
