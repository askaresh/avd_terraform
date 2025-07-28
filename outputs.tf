/**
* Outputs expose key information about the deployed AVD environment.  These
* values can be used by other Terraform configurations or for reference when
* managing the environment manually.  The workspace URL provides direct access
* to the deployed desktops for testing.
*/

output "resource_group_name" {
  description = "Name of the resource group containing all AVD resources"
  value       = azurerm_resource_group.avd.name
}

output "host_pool_name" {
  description = "Name of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.avd.name
}

output "host_pool_id" {
  description = "Resource ID of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.avd.id
}

output "application_group_name" {
  description = "Name of the AVD application group"
  value       = azurerm_virtual_desktop_application_group.avd.name
}

output "application_group_id" {
  description = "Resource ID of the AVD application group"
  value       = azurerm_virtual_desktop_application_group.avd.id
}

output "workspace_name" {
  description = "Name of the AVD workspace"
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
  description = "Network configuration details"
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