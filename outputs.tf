/**
* Output values useful when consuming the module.  These outputs expose
* identifiers for the created resources and can be used for verification or
* integration with other Terraform configurations.
*/

output "resource_group_name" {
  description = "Name of the resource group containing all AVD resources."
  value       = azurerm_resource_group.avd.name
}

output "host_pool_name" {
  description = "Name of the host pool created by this configuration."
  value       = azurerm_virtual_desktop_host_pool.avd.name
}

output "workspace_name" {
  description = "Name of the workspace associated with the application group."
  value       = azurerm_virtual_desktop_workspace.avd.name
}

output "session_host_names" {
  description = "List of names of session host VMs.  Useful for verifying the number of hosts deployed."
  value       = [for vm in azurerm_windows_virtual_machine.session_host : vm.name]
}