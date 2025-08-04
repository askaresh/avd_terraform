/**
* Outputs expose key information about the deployed AVD environment.  These
* values can be used by other Terraform configurations or for reference when
* managing the environment manually.  The workspace URL provides direct access
* to the deployed desktops for testing.
* 
* Resource names follow Microsoft Cloud Adoption Framework naming standards:
* - Host Pools: vdpool-[prefix]-[environment]-[deployment-suffix]
* - Application Groups: vdag-[prefix]-[environment]-[deployment-suffix]
* - Workspaces: vdws-[prefix]-[environment]
* - Subnets: snet-[prefix]-[environment]
*/

output "resource_group_name" {
  description = "Name of the resource group containing all AVD resources"
  value       = azurerm_resource_group.avd.name
}

output "host_pool_name" {
  description = "Name of the AVD host pool (follows pattern: vdpool-[prefix]-[environment]-[deployment-suffix])"
  value       = azurerm_virtual_desktop_host_pool.avd.name
}

output "host_pool_id" {
  description = "Resource ID of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.avd.id
}

output "application_group_name" {
  description = "Name of the AVD application group (follows pattern: vdag-[prefix]-[environment]-[deployment-suffix])"
  value       = azurerm_virtual_desktop_application_group.avd.name
}

output "application_group_id" {
  description = "Resource ID of the AVD application group"
  value       = azurerm_virtual_desktop_application_group.avd.id
}

output "workspace_name" {
  description = "Name of the AVD workspace (follows pattern: vdws-[prefix]-[environment])"
  value       = azurerm_virtual_desktop_workspace.avd.name
}

output "workspace_id" {
  description = "Resource ID of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.avd.id
}

output "workspace_url" {
  description = "Direct URL to access the AVD workspace via web client"
  value       = "https://rdweb.wvd.microsoft.com/arm/webclient/index.html"
}

output "deployment_type" {
  description = "The type of AVD deployment that was created"
  value       = var.deployment_type
}

output "naming_convention" {
  description = "Microsoft-compliant naming patterns used for this deployment"
  value = {
    host_pool_pattern     = "vdpool-${var.prefix}-${var.environment}-${local.deployment_suffixes[var.deployment_type]}"
    app_group_pattern     = "vdag-${var.prefix}-${var.environment}-${local.deployment_suffixes[var.deployment_type]}"
    workspace_pattern     = "vdws-${var.prefix}-${var.environment}"
    subnet_pattern        = "snet-${var.prefix}-${var.environment}"
    deployment_suffix     = local.deployment_suffixes[var.deployment_type]
    follows_standards     = "Microsoft Cloud Adoption Framework"
  }
}

output "deployment_config" {
  description = "Configuration details for the deployed AVD environment"
  value = {
    deployment_type     = var.deployment_type
    host_pool_type     = local.current_config.host_pool_type
    app_group_type     = local.current_config.app_group_type
    load_balancer_type = local.current_config.load_balancer_type
    max_sessions       = local.current_config.max_sessions
    start_vm_on_connect = local.current_config.start_vm_on_connect
    session_host_count = var.session_host_count
    vm_size           = var.vm_size
  }
}

output "published_applications" {
  description = "List of published applications (for RemoteApp deployments)"
  value = local.current_config.supports_applications ? [
    for app in azurerm_virtual_desktop_application.apps : {
      name         = app.name
      display_name = app.friendly_name
      description  = app.description
      path         = app.path
    }
  ] : []
}

output "session_host_names" {
  description = "Names of the deployed session host virtual machines"
  value       = [for vm in azurerm_windows_virtual_machine.session_host : vm.name]
}

output "network_details" {
  description = "Network configuration details (subnet follows pattern: snet-[prefix]-[environment])"
  value = {
    vnet_name           = azurerm_virtual_network.avd.name
    vnet_address_space  = azurerm_virtual_network.avd.address_space
    subnet_name         = azurerm_subnet.avd.name
    subnet_address_prefix = azurerm_subnet.avd.address_prefixes[0]
  }
}

output "registration_token_expiration" {
  description = "When the host pool registration token expires"
  value       = azurerm_virtual_desktop_host_pool_registration_info.avd.expiration_date
}

# =============================================================================
# MONITORING AND SCALING OUTPUTS
# =============================================================================

output "monitoring_enabled" {
  description = "Whether monitoring features are enabled for this deployment"
  value       = var.enable_monitoring
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace (if monitoring is enabled)"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.avd_monitoring[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace (if monitoring is enabled)"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.avd_monitoring[0].name : null
}

output "scaling_plans_enabled" {
  description = "Whether scaling plans are enabled for this deployment"
  value       = var.enable_scaling_plans
}

output "scaling_plan_id" {
  description = "Resource ID of the AVD scaling plan (if scaling is enabled)"
  value       = var.enable_scaling_plans && local.should_enable_scaling ? azurerm_virtual_desktop_scaling_plan.avd[0].id : null
}

output "scaling_plan_name" {
  description = "Name of the AVD scaling plan (if scaling is enabled)"
  value       = var.enable_scaling_plans && local.should_enable_scaling ? azurerm_virtual_desktop_scaling_plan.avd[0].name : null
}

output "scaling_schedules" {
  description = "Scaling schedules configured for this deployment"
  value       = var.enable_scaling_plans && local.should_enable_scaling ? local.scaling_schedules : []
}

output "scaling_plan_role_id" {
  description = "The ID of the built-in scaling plan role"
  value       = var.enable_scaling_plans && local.should_enable_scaling ? data.azurerm_role_definition.avd_power_role[0].id : null
}

output "scaling_plan_role_name" {
  description = "The name of the built-in scaling plan role"
  value       = var.enable_scaling_plans && local.should_enable_scaling ? data.azurerm_role_definition.avd_power_role[0].name : null
}

output "scaling_plan_host_pool_association_id" {
  description = "The ID of the scaling plan host pool association"
  value       = var.enable_scaling_plans && local.should_enable_scaling ? azurerm_virtual_desktop_scaling_plan_host_pool_association.avd[0].id : null
}

output "scaling_plan_role_assignment_id" {
  description = "The ID of the scaling plan role assignment"
  value       = var.enable_scaling_plans && local.should_enable_scaling ? azurerm_role_assignment.scaling_plan[0].id : null
}

output "cost_alerts_enabled" {
  description = "Whether cost monitoring alerts are enabled"
  value       = var.enable_cost_alerts
}

output "cost_alert_threshold" {
  description = "Cost alert threshold in USD"
  value       = var.enable_cost_alerts ? var.cost_alert_threshold : null
}

output "dashboard_enabled" {
  description = "Whether custom dashboards are enabled for this deployment"
  value       = var.enable_dashboards
}

output "dashboard_id" {
  description = "Resource ID of the custom AVD dashboard (if dashboards are enabled)"
  value       = var.enable_dashboards ? azurerm_portal_dashboard.avd_insights[0].id : null
}

output "dashboard_name" {
  description = "Name of the custom AVD dashboard (if dashboards are enabled)"
  value       = var.enable_dashboards ? azurerm_portal_dashboard.avd_insights[0].name : null
}

output "monitoring_insights" {
  description = "Comprehensive monitoring and scaling insights for this deployment"
  value = {
    monitoring_enabled     = var.enable_monitoring
    scaling_enabled        = var.enable_scaling_plans && local.should_enable_scaling
    cost_alerts_enabled    = var.enable_cost_alerts
    dashboard_enabled      = var.enable_dashboards
    retention_days         = var.enable_monitoring ? var.monitoring_retention_days : null
    scaling_schedules      = var.enable_scaling_plans && local.should_enable_scaling ? length(local.scaling_schedules) : 0
    scaling_role_type      = var.enable_scaling_plans && local.should_enable_scaling ? "built-in" : null
    deployment_type        = var.deployment_type
    environment            = var.environment
    resource_group         = azurerm_resource_group.avd.name
  }
}

output "quick_links" {
  description = "Quick access links for monitoring and management"
  value = {
    workspace_url          = "https://rdweb.wvd.microsoft.com/arm/webclient/index.html"
    azure_portal_host_pool = "https://portal.azure.com/#@/resource${azurerm_virtual_desktop_host_pool.avd.id}"
    log_analytics          = var.enable_monitoring ? "https://portal.azure.com/#@/resource${azurerm_log_analytics_workspace.avd_monitoring[0].id}" : null
    dashboard              = var.enable_dashboards ? "https://portal.azure.com/#@/resource${azurerm_portal_dashboard.avd_insights[0].id}" : null
    scaling_plan           = var.enable_scaling_plans && local.should_enable_scaling ? "https://portal.azure.com/#@/resource${azurerm_virtual_desktop_scaling_plan.avd[0].id}" : null
  }
}