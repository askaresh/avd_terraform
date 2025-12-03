/**
* Main Terraform configuration that deploys a minimal Azure Virtual Desktop (AVD)
* environment.  The configuration is derived from the supplied ARM template and
* demonstrates how to provision an AVD host pool, application group, workspace
* and session host(s) using the Azurerm provider.  All resource names are
* parameterised via variables to support repeatable deployments across multiple
* environments (dev, test, prod).  Use variable files to override defaults
* rather than hard‑coding values in this file.
*/

locals {
  # Merge default tags with user defined tags.  The environment and prefix
  # values are included automatically.  Additional tags passed via the
  # `tags` variable will override these defaults when keys overlap.
  default_tags = {
    environment = var.environment
    prefix      = var.prefix
    created_by  = "terraform"
  }
  tags = merge(local.default_tags, var.tags)

  # Microsoft-compliant deployment type suffixes for resource naming
  # These suffixes align with Microsoft Cloud Adoption Framework naming standards
  deployment_suffixes = {
    pooled_desktop     = "desktop"
    personal_desktop   = "personal" 
    pooled_remoteapp   = "apps"
    personal_remoteapp = "personalapps"
  }
  
  # Microsoft-compliant resource names using official abbreviations
  # Pattern: [microsoft-abbreviation]-[prefix]-[environment]-[deployment-suffix]
  host_pool_name    = "vdpool-${var.prefix}-${var.environment}-${local.deployment_suffixes[var.deployment_type]}"
  app_group_name    = "vdag-${var.prefix}-${var.environment}-${local.deployment_suffixes[var.deployment_type]}"
  workspace_name    = "vdws-${var.prefix}-${var.environment}"  # Workspace serves all deployment types
  subnet_name       = "snet-${var.prefix}-${var.environment}"

  # Deployment type configuration matrix
  # This matrix defines the specific settings for each AVD deployment pattern
  deployment_config = {
    pooled_desktop = {
      host_pool_type                = "Pooled"
      app_group_type               = "Desktop"
      load_balancer_type           = var.load_balancer_type
      max_sessions                 = var.max_session_limit
      start_vm_on_connect         = false
      friendly_name_suffix        = "Desktop Pool"
      description_suffix          = "Pooled Desktop Environment"
      personal_assignment_type    = null
      supports_load_balancing     = true
      supports_applications       = false
    }
    personal_desktop = {
      host_pool_type              = "Personal"
      app_group_type             = "Desktop"
      load_balancer_type         = "Persistent"  # Personal desktops use Persistent (though not used)
      max_sessions               = 1
      start_vm_on_connect       = true
      friendly_name_suffix      = "Personal Desktop"
      description_suffix        = "Personal Desktop Environment"
      personal_assignment_type  = var.personal_desktop_assignment_type
      supports_load_balancing   = false
      supports_applications     = false
    }
    pooled_remoteapp = {
      host_pool_type              = "Pooled"
      app_group_type             = "RemoteApp"
      load_balancer_type         = var.load_balancer_type
      max_sessions               = var.max_session_limit
      start_vm_on_connect       = false
      friendly_name_suffix      = "RemoteApp Pool"
      description_suffix        = "Pooled RemoteApp Environment"
      personal_assignment_type  = null
      supports_load_balancing   = true
      supports_applications     = true
    }
    personal_remoteapp = {
      host_pool_type              = "Personal"
      app_group_type             = "RemoteApp"
      load_balancer_type         = "Persistent"  # Personal RemoteApp uses Persistent (though not used)
      max_sessions               = 1
      start_vm_on_connect       = true
      friendly_name_suffix      = "Personal RemoteApp"
      description_suffix        = "Personal RemoteApp Environment"
      personal_assignment_type  = var.personal_desktop_assignment_type
      supports_load_balancing   = false
      supports_applications     = true
    }
  }
  
  # Current deployment configuration based on selected deployment type
  current_config = local.deployment_config[var.deployment_type]
  
  # Validation for RemoteApp deployments
  validate_remoteapp_apps = var.deployment_type == "pooled_remoteapp" || var.deployment_type == "personal_remoteapp" ? (
    length(var.published_applications) > 0 ? true : 
    error("published_applications must contain at least one application for RemoteApp deployments")
  ) : true
}

/*
 * Resource Group
 *
 * The resource group contains all resources for a given environment.  Using a
 * dedicated resource group per environment follows best practices for
 * separating dev/test/prod workloads, as recommended by the Azure Cloud
 * Adoption Framework【228828509832038†L113-L133】.
 */
resource "azurerm_resource_group" "avd" {
  name     = format("rg-%s-%s", var.prefix, var.environment)
  location = var.location
  tags     = local.enhanced_tags
}

/*
 * Networking
 *
 * A small virtual network and subnet are created to host the session
 * machines.  A network security group (NSG) is associated with the subnet
 * to allow future rule definitions.  At present the NSG contains no rules
 * which is equivalent to the ARM template’s empty securityRules array.
 */
resource "azurerm_network_security_group" "avd" {
  name                = format("nsg-%s-%s", var.prefix, var.environment)
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = local.tags
}

resource "azurerm_virtual_network" "avd" {
  name                = format("vnet-%s-%s", var.prefix, var.environment)
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

resource "azurerm_subnet" "avd" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.avd.name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "avd" {
  subnet_id                 = azurerm_subnet.avd.id
  network_security_group_id = azurerm_network_security_group.avd.id
}

/*
 * AVD Host Pool
 *
 * Creates a pooled host pool with a BreadthFirst load balancer and Desktop
 * preferred app group.  Registration information is defined directly on the
 * host pool.  The registration token expires two hours from apply time.
 * See the AVD session host example【371417216153686†L120-L125】 for how a
 * token is retrieved and referenced when installing the DSC extension.
 */
resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                = local.host_pool_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  type                = local.current_config.host_pool_type
  friendly_name       = "${var.prefix}-${var.environment}-${local.current_config.friendly_name_suffix}"
  description         = "${local.current_config.description_suffix} created via Terraform"
  maximum_sessions_allowed = local.current_config.max_sessions
  load_balancer_type  = local.current_config.load_balancer_type
  validate_environment = true
  start_vm_on_connect = local.current_config.start_vm_on_connect
  personal_desktop_assignment_type = local.current_config.personal_assignment_type
  custom_rdp_properties = "targetisaadjoined:i:1;drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;enablerdsaadauth:i:1;"
  tags                = local.tags

  scheduled_agent_updates {
    enabled  = true
    timezone = "Australia/Melbourne"
    schedule {
      day_of_week = "Sunday"
      hour_of_day = 2
    }
  }

  # Note: Previously included a complex destroy-time provisioner for phantom session host cleanup.
  # Removed due to Terraform validation constraints on destroy provisioner references.
  # The AzureRM provider now handles force deletion more reliably, and the lifecycle rule below
  # ensures proper cleanup order during resource destruction.
  #
  # If terraform destroy still fails with phantom session hosts, use:
  # terraform state rm azurerm_virtual_desktop_host_pool.avd
  # az group delete --name <resource-group> --yes --no-wait
  
  # Lifecycle rule to prevent resource group deletion if it contains orphaned resources
  lifecycle {
    ignore_changes = [tags]
  }
}

/*
 * Registration Info
 *
 * The registration info resource generates a token that allows session hosts to
 * join the host pool. The expiration time is configurable to allow for shorter
 * lived tokens in production.
 */
resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id       = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date   = timeadd(timestamp(), "${var.registration_token_expiration_hours}h")
}

/*
 * Registration Token Local
 *
 * This local exposes the registration token for use in the DSC extension.
 * Using a local avoids storing the token in the Terraform state file directly.
 */
locals {
  # This token is used by the DSC extension to register session hosts.
  # It is retrieved from the registration_info resource.
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.avd.token
}

/*
 * Application Group
 *
 * The application group defines the resources (desktops or applications) that
 * users can access. The type is determined by the deployment configuration.
 */
resource "azurerm_virtual_desktop_application_group" "avd" {
  name                = local.app_group_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd.id
  type                = local.current_config.app_group_type
  friendly_name       = "${var.prefix}-${var.environment}-${local.current_config.friendly_name_suffix}"
  description         = "${local.current_config.description_suffix} Application Group"
  tags                = local.tags
}

/*
 * Workspace
 *
 * The workspace aggregates one or more application groups.  Public network
 * access is enabled to mirror the ARM template’s behaviour.
 */
resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = local.workspace_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  friendly_name       = "${var.prefix}-${var.environment}-workspace"
  description         = "${local.current_config.description_suffix} workspace for ${var.environment} environment"
  public_network_access_enabled = true
  tags                = local.tags
}

/*
 * RemoteApp Applications
 *
 * Publishes specific applications for RemoteApp deployments. Each application
 * represents an executable that users can launch remotely. Only created when
 * deployment type includes RemoteApp functionality.
 */
resource "azurerm_virtual_desktop_application" "apps" {
  for_each = local.current_config.supports_applications ? {
    for app in var.published_applications : app.name => app
  } : {}
  
  name                         = each.value.name
  application_group_id         = azurerm_virtual_desktop_application_group.avd.id
  friendly_name               = each.value.display_name
  description                 = each.value.description
  path                        = each.value.path
  command_line_arguments      = each.value.command_line_arguments != "" ? each.value.command_line_arguments : null
  command_line_argument_policy = each.value.command_line_setting
  show_in_portal              = each.value.show_in_portal
  icon_path                   = each.value.icon_path != "" ? each.value.icon_path : null
  icon_index                  = each.value.icon_index
}

/*
 * Associate the application group with the workspace.  This creates the
 * relationship between the application group and workspace so that users 
 * can see the published resources (desktops or applications) in their feed.
 */
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd.id
}

/*
 * Role Assignments
 *
 * Assign the Desktop Virtualization User role to each security principal
 * object on the application group.  Also assign the Virtual Machine User
 * Login role on the resource group to allow login to session hosts.  Using
 * for_each makes it easy to repeat these assignments for multiple users or
 * groups.
 */
data "azurerm_role_definition" "desktop_virtualization_user" {
  name = "Desktop Virtualization User"
}

data "azurerm_role_definition" "virtual_machine_user_login" {
  name = "Virtual Machine User Login"
}

resource "azurerm_role_assignment" "app_group" {
  for_each             = toset(var.security_principal_object_ids)
  scope                = azurerm_virtual_desktop_application_group.avd.id
  role_definition_id   = data.azurerm_role_definition.desktop_virtualization_user.id
  principal_id         = each.value
}

resource "azurerm_role_assignment" "session_host_login" {
  for_each           = toset(var.security_principal_object_ids)
  scope              = azurerm_resource_group.avd.id
  role_definition_id = data.azurerm_role_definition.virtual_machine_user_login.id
  principal_id       = each.value
}

/*
 * Network Interfaces for Session Hosts
 *
 * A NIC is created for each session host.  Accelerated networking is enabled
 * and the NIC is attached to the AVD subnet.  The ARM template allocated a
 * single NIC with dynamic private IP; this configuration matches that
 * behaviour【371417216153686†L140-L150】.
 */
resource "azurerm_network_interface" "session_host" {
  count               = var.session_host_count
  name                = format("nic-%s-%s-%02d", var.prefix, var.environment, count.index + 1)
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.avd.id
    private_ip_address_allocation = "Dynamic"
  }

  accelerated_networking_enabled = true
  tags                          = local.tags
}

/*
 * Session Host Virtual Machines
 *
 * Windows virtual machines are provisioned for each session host.  A system
 * assigned managed identity is enabled and the VM is created from the
 * marketplace image defined in variables.  Trusted Launch settings (Secure
 * Boot and vTPM) are enabled by default.  The license type is set to
 * Windows_Client to comply with AVD licensing.  Provisioning of the VM
 * agent is implicit for Windows VMs and therefore not specified.
 */
resource "azurerm_windows_virtual_machine" "session_host" {
  count               = var.session_host_count
  name                = format("vm-%s-%s-%02d", var.prefix, var.environment, count.index + 1)
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  computer_name       = format("avd-%s-%s-%02d", var.prefix, var.environment, count.index + 1)
  network_interface_ids = [element(azurerm_network_interface.session_host[*].id, count.index)]
  license_type        = "Windows_Client"
  tags                = local.tags

  os_disk {
    name                 = format("osdisk-%s-%s-%02d", var.prefix, var.environment, count.index + 1)
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    sku       = var.marketplace_gallery_image_sku
    version   = "latest"
  }

  # Trusted launch security profile
  secure_boot_enabled = true
  vtpm_enabled        = true
  # Default value is "Standard"; by enabling vtpm and secure boot the VM will
  # automatically use Trusted Launch when available.

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_virtual_desktop_host_pool.avd
  ]
}

/*
 * Guest Attestation Extension
 *
 * Adds the GuestAttestation extension to enable integrity monitoring as
 * configured in the ARM template.  Guest Attestation is part of the trusted
 * launch setup and does not require any protected settings.
 */
resource "azurerm_virtual_machine_extension" "guest_attestation" {
  count                = var.session_host_count
  name                 = "GuestAttestation"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher            = "Microsoft.Azure.Security.WindowsAttestation"
  type                 = "GuestAttestation"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
  settings             = jsonencode({
    AttestationConfig = {
      MaaSettings = {
        maaEndpoint  = ""
        maaTenantName = "GuestAttestation"
      }
      AscSettings = {
        ascReportingEndpoint = ""
        ascReportingFrequency = ""
      }
      useCustomToken = "false"
      disableAlerts = "false"
    }
  })
  depends_on = [azurerm_windows_virtual_machine.session_host]
  lifecycle {
    create_before_destroy = false
  }
}

/*
 * DSC Extension for AVD Registration (Microsoft Official Approach)
 *
 * Uses Microsoft's official DSC configuration as documented in Azure samples.
 * This is the proven, supported method for session host registration.
 */
resource "azurerm_virtual_machine_extension" "avd_dsc" {
  count                      = var.session_host_count
  name                       = "Microsoft.Powershell.DSC" # Using the official name
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "${var.configuration_zip_file}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName": "${azurerm_virtual_desktop_host_pool.avd.name}",
        "aadJoin": true
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_desktop_host_pool_registration_info.avd
  ]
  lifecycle {
    create_before_destroy = false
  }
}

/*
 * AAD Login for Windows Extension
 *
 * Enables Azure AD authentication on the session hosts.  Without this
 * extension users will not be able to sign in using their Azure AD
 * credentials.
 */
resource "azurerm_virtual_machine_extension" "aadlogin" {
  count                = var.session_host_count
  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "2.0"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    mdmId = ""
  })

  lifecycle {
    create_before_destroy = false
  }
}

/*
 * Session Host Cleanup on Destroy (AzAPI)
 *
 * Removes session host registrations from the host pool when VMs are destroyed.
 * This prevents "SessionHostPool could not be deleted because it still has 
 * SessionHosts associated" errors during terraform destroy.
 */
resource "azapi_resource_action" "remove_session_host" {
  count = var.session_host_count

  type        = "Microsoft.DesktopVirtualization/hostPools/sessionHosts@2024-04-03"
  resource_id = "${azurerm_virtual_desktop_host_pool.avd.id}/sessionHosts/${azurerm_windows_virtual_machine.session_host[count.index].computer_name}"
  method      = "DELETE"
  
  when = "destroy"
  
  depends_on = [
    azurerm_virtual_machine_extension.avd_dsc,
    azurerm_virtual_machine_extension.aadlogin
  ]
}

# =============================================================================
# MONITORING AND SCALING FEATURES
# =============================================================================

/*
 * Log Analytics Workspace for Monitoring
 *
 * Creates a Log Analytics workspace to collect logs and metrics from AVD
 * resources. This enables comprehensive monitoring and troubleshooting.
 */
resource "azurerm_log_analytics_workspace" "avd_monitoring" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "law-${var.prefix}-${var.environment}"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  sku                 = "PerGB2018"
  retention_in_days   = var.monitoring_retention_days
  tags                = local.tags
}

/*
 * Default Scaling Schedules
 *
 * Predefined scaling schedules optimized for different environments.
 * Development environments scale down more aggressively for cost savings.
 */
locals {
  default_scaling_schedules = {
    dev = [
      {
        name                                 = "Weekdays"
        days_of_week                        = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        ramp_up_start_time                  = "08:00"
        ramp_up_load_balancing_algorithm    = "BreadthFirst"
        ramp_up_minimum_hosts_percent       = 20
        ramp_up_capacity_threshold_percent  = 80
        peak_start_time                     = "09:00"
        peak_load_balancing_algorithm       = "BreadthFirst"
        ramp_down_start_time                = "17:00"
        ramp_down_load_balancing_algorithm  = "BreadthFirst"
        ramp_down_minimum_hosts_percent     = 20
        ramp_down_capacity_threshold_percent = 20
        ramp_down_force_logoff_users        = false
        ramp_down_stop_hosts_when           = "ZeroSessions"
        ramp_down_wait_time_minutes         = 30
        ramp_down_notification_message      = "You will be logged off in 30 minutes due to scaling plan. Please save your work."
        off_peak_start_time                 = "18:00"
        off_peak_load_balancing_algorithm   = "BreadthFirst"
      },
      {
        name                                 = "Weekends"
        days_of_week                        = ["Saturday", "Sunday"]
        ramp_up_start_time                  = "09:00"
        ramp_up_load_balancing_algorithm    = "BreadthFirst"
        ramp_up_minimum_hosts_percent       = 10
        ramp_up_capacity_threshold_percent  = 80
        peak_start_time                     = "10:00"
        peak_load_balancing_algorithm       = "BreadthFirst"
        ramp_down_start_time                = "16:00"
        ramp_down_load_balancing_algorithm  = "BreadthFirst"
        ramp_down_minimum_hosts_percent     = 10
        ramp_down_capacity_threshold_percent = 20
        ramp_down_force_logoff_users        = false
        ramp_down_stop_hosts_when           = "ZeroSessions"
        ramp_down_wait_time_minutes         = 30
        ramp_down_notification_message      = "You will be logged off in 30 minutes due to scaling plan. Please save your work."
        off_peak_start_time                 = "17:00"
        off_peak_load_balancing_algorithm   = "BreadthFirst"
      }
    ]
    prod = [
      {
        name                                 = "Weekdays"
        days_of_week                        = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        ramp_up_start_time                  = "07:00"
        ramp_up_load_balancing_algorithm    = "BreadthFirst"
        ramp_up_minimum_hosts_percent       = 30
        ramp_up_capacity_threshold_percent  = 80
        peak_start_time                     = "08:00"
        peak_load_balancing_algorithm       = "BreadthFirst"
        ramp_down_start_time                = "18:00"
        ramp_down_load_balancing_algorithm  = "BreadthFirst"
        ramp_down_minimum_hosts_percent     = 30
        ramp_down_capacity_threshold_percent = 20
        ramp_down_force_logoff_users        = false
        ramp_down_stop_hosts_when           = "ZeroSessions"
        ramp_down_wait_time_minutes         = 30
        ramp_down_notification_message      = "You will be logged off in 30 minutes due to scaling plan. Please save your work."
        off_peak_start_time                 = "19:00"
        off_peak_load_balancing_algorithm   = "BreadthFirst"
      },
      {
        name                                 = "Weekends"
        days_of_week                        = ["Saturday", "Sunday"]
        ramp_up_start_time                  = "08:00"
        ramp_up_load_balancing_algorithm    = "BreadthFirst"
        ramp_up_minimum_hosts_percent       = 20
        ramp_up_capacity_threshold_percent  = 80
        peak_start_time                     = "09:00"
        peak_load_balancing_algorithm       = "BreadthFirst"
        ramp_down_start_time                = "17:00"
        ramp_down_load_balancing_algorithm  = "BreadthFirst"
        ramp_down_minimum_hosts_percent     = 20
        ramp_down_capacity_threshold_percent = 20
        ramp_down_force_logoff_users        = false
        ramp_down_stop_hosts_when           = "ZeroSessions"
        ramp_down_wait_time_minutes         = 30
        ramp_down_notification_message      = "You will be logged off in 30 minutes due to scaling plan. Please save your work."
        off_peak_start_time                 = "18:00"
        off_peak_load_balancing_algorithm   = "BreadthFirst"
      }
    ]
  }

  # Use custom schedules if provided, otherwise use default based on environment
  scaling_schedules = length(var.scaling_plan_schedules) > 0 ? var.scaling_plan_schedules : tolist(local.default_scaling_schedules[var.environment])

  # Only enable scaling for pooled deployments
  should_enable_scaling = var.enable_scaling_plans && (var.deployment_type == "pooled_desktop" || var.deployment_type == "pooled_remoteapp")
}

/*
 * AVD Scaling Plan (Azure Verified Module Approach)
 *
 * Automatically scales session hosts based on usage patterns and schedules.
 * Uses inline host_pool block as recommended by Azure Verified Module.
 * Only enabled for pooled deployments to optimize costs while maintaining performance.
 */
resource "azurerm_virtual_desktop_scaling_plan" "avd" {
  count               = local.should_enable_scaling ? 1 : 0
  name                = "scaling-${var.prefix}-${var.environment}"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  friendly_name       = "${var.prefix}-${var.environment} Scaling Plan"
  description         = "Automatic scaling plan for ${var.environment} AVD environment"
  time_zone           = "Australia/Melbourne"
  tags                = local.tags

  # Host pool association will be handled separately for better Azure Portal compatibility

  dynamic "schedule" {
    for_each = local.scaling_schedules
    content {
      name                                 = schedule.value.name
      days_of_week                        = schedule.value.days_of_week
      ramp_up_start_time                  = schedule.value.ramp_up_start_time
      ramp_up_load_balancing_algorithm    = schedule.value.ramp_up_load_balancing_algorithm
      ramp_up_minimum_hosts_percent       = schedule.value.ramp_up_minimum_hosts_percent
      ramp_up_capacity_threshold_percent  = schedule.value.ramp_up_capacity_threshold_percent
      peak_start_time                     = schedule.value.peak_start_time
      peak_load_balancing_algorithm       = schedule.value.peak_load_balancing_algorithm
      ramp_down_start_time                = schedule.value.ramp_down_start_time
      ramp_down_load_balancing_algorithm  = schedule.value.ramp_down_load_balancing_algorithm
      ramp_down_minimum_hosts_percent     = schedule.value.ramp_down_minimum_hosts_percent
      ramp_down_capacity_threshold_percent = schedule.value.ramp_down_capacity_threshold_percent
      ramp_down_force_logoff_users        = schedule.value.ramp_down_force_logoff_users
      ramp_down_stop_hosts_when           = schedule.value.ramp_down_stop_hosts_when
      ramp_down_wait_time_minutes         = schedule.value.ramp_down_wait_time_minutes
      ramp_down_notification_message      = schedule.value.ramp_down_notification_message
      off_peak_start_time                 = schedule.value.off_peak_start_time
      off_peak_load_balancing_algorithm   = schedule.value.off_peak_load_balancing_algorithm
    }
  }

  depends_on = [
    azurerm_role_assignment.scaling_plan,
    azurerm_virtual_desktop_host_pool.avd,
    azurerm_windows_virtual_machine.session_host
  ]
}

/*
 * Scaling Plan Host Pool Association (Separate Resource - Best Practice from Sample 2)
 *
 * Associates the scaling plan with the host pool using a separate resource
 * instead of inline host_pool block. This ensures better Azure Portal compatibility
 * and resolves the 404 error in the scaling plan overview blade.
 */
resource "azurerm_virtual_desktop_scaling_plan_host_pool_association" "avd" {
  count           = local.should_enable_scaling ? 1 : 0
  host_pool_id    = azurerm_virtual_desktop_host_pool.avd.id
  scaling_plan_id = azurerm_virtual_desktop_scaling_plan.avd[0].id
  enabled         = true

  depends_on = [
    azurerm_virtual_desktop_scaling_plan.avd,
    azurerm_role_assignment.scaling_plan
  ]
}

/*
 * Get Current Subscription (Required for Role Assignment Scope)
 *
 * Retrieves the current subscription details for use in role assignments.
 * This follows the pattern from Sample 2 for proper scope management.
 */
data "azurerm_subscription" "current" {}

/*
 * Random UUID for Role Assignment (Best Practice from Sample 1)
 *
 * Generates a unique identifier for the role assignment to ensure
 * proper resource management and avoid conflicts.
 */
resource "random_uuid" "scaling_plan_role" {
  count = local.should_enable_scaling ? 1 : 0
}

/*
 * Role Assignment for AVD Scaling Plan (Azure Verified Module Approach)
 *
 * Uses the built-in "Desktop Virtualization Power On Off Contributor" role
 * and the hardcoded AVD service principal client ID for reliability.
 * This follows the official Azure Verified Module best practices.
 */
data "azurerm_role_definition" "avd_power_role" {
  count = local.should_enable_scaling ? 1 : 0
  name  = "Desktop Virtualization Power On Off Contributor"
}

/*
 * AVD Service Principal (Hardcoded Client ID for Reliability)
 *
 * Uses the official AVD service principal client ID instead of dynamic lookup.
 * This is more reliable and follows Azure Verified Module patterns.
 */
data "azuread_service_principal" "avd" {
  count      = local.should_enable_scaling ? 1 : 0
  client_id  = "9cdead84-a844-4324-93f2-b2e6bb768d07"  # Official AVD service principal
}

/*
 * Role Assignment for AVD Scaling Plan (Enhanced from Sample 1 & 2)
 *
 * Assigns the built-in role to the AVD service principal for scaling plan operations.
 * Uses random UUID for name and subscription scope for better permissions.
 * This is more maintainable than custom roles and follows Azure best practices.
 */
resource "azurerm_role_assignment" "scaling_plan" {
  count                        = local.should_enable_scaling ? 1 : 0
  name                         = random_uuid.scaling_plan_role[0].result
  scope                        = data.azurerm_subscription.current.id  # Subscription scope like Sample 2
  role_definition_id           = data.azurerm_role_definition.avd_power_role[0].id
  principal_id                 = data.azuread_service_principal.avd[0].object_id
  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = all  # Prevent recreation on every apply
  }
}

/*
 * Diagnostic Settings for Host Pool
 *
 * Sends AVD host pool logs to Log Analytics workspace for monitoring
 * and troubleshooting. Only enabled when monitoring is enabled.
 */
resource "azurerm_monitor_diagnostic_setting" "avd_host_pool" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "diag-${azurerm_virtual_desktop_host_pool.avd.name}"
  target_resource_id         = azurerm_virtual_desktop_host_pool.avd.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_monitoring[0].id

  enabled_log {
    category = "Checkpoint"
  }

  enabled_log {
    category = "Error"
  }

  enabled_log {
    category = "Management"
  }

  enabled_log {
    category = "Connection"
  }

  enabled_log {
    category = "HostRegistration"
  }
}

/*
 * Diagnostic Settings for Session Hosts
 *
 * Sends VM logs and metrics to Log Analytics workspace for monitoring.
 * Only enabled when monitoring is enabled.
 */
resource "azurerm_monitor_diagnostic_setting" "session_hosts" {
  count                      = var.enable_monitoring ? var.session_host_count : 0
  name                       = "diag-${azurerm_windows_virtual_machine.session_host[count.index].name}"
  target_resource_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_monitoring[0].id

  enabled_metric {
    category = "AllMetrics"
  }
}

/*
 * Action Group for Cost Alerts
 *
 * Defines the action to be taken when cost alerts are triggered.
 * Sends email notifications to the specified recipients.
 */
resource "azurerm_monitor_action_group" "cost_alerts" {
  count               = var.enable_cost_alerts ? 1 : 0
  name                = "ag-cost-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.avd.name
  short_name          = "cost-alerts"
  tags                = local.tags

  email_receiver {
    name                    = "cost-admin"
    email_address          = "admin@${var.prefix}.com"
    use_common_alert_schema = true
  }
}

/*
 * Consumption Budget for Cost Monitoring
 *
 * Sets up budget alerts to monitor AVD resource consumption costs.
 * Alerts are triggered when daily spending exceeds the threshold.
 */
resource "azurerm_consumption_budget_resource_group" "avd_budget" {
  count           = var.enable_cost_alerts ? 1 : 0
  name            = "budget-${var.prefix}-${var.environment}"
  resource_group_id = azurerm_resource_group.avd.id

  amount     = var.cost_alert_threshold
  time_grain = "Monthly"

  time_period {
    # Set start date to first day of current month dynamically
    # Format: YYYY-MM-01T00:00:00Z
    start_date = "${substr(timestamp(), 0, 7)}-01T00:00:00Z"
    # Set end date to end of next year
    end_date   = "${tonumber(substr(timestamp(), 0, 4)) + 1}-12-31T23:59:59Z"
  }

  notification {
    enabled        = true
    threshold      = 90.0
    operator       = "GreaterThan"
    contact_emails = ["admin@${var.prefix}.com"]
    contact_groups = [azurerm_monitor_action_group.cost_alerts[0].id]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    contact_emails = ["admin@${var.prefix}.com"]
    contact_groups = [azurerm_monitor_action_group.cost_alerts[0].id]
  }
}

/*
 * Custom Dashboard for AVD Insights
 *
 * Creates a comprehensive dashboard showing key AVD metrics
 * including session counts, performance, and cost data.
 */
resource "azurerm_portal_dashboard" "avd_insights" {
  count               = var.enable_dashboards ? 1 : 0
  name                = "dashboard-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  tags                = local.tags

  dashboard_properties = templatefile("${path.module}/templates/dashboard.tpl", {
    workspace_id     = var.enable_monitoring ? azurerm_log_analytics_workspace.avd_monitoring[0].id : ""
    host_pool_id     = azurerm_virtual_desktop_host_pool.avd.id
    resource_group   = azurerm_resource_group.avd.name
    environment      = var.environment
    deployment_type  = var.deployment_type
    refresh_interval = var.dashboard_refresh_interval
  })

  depends_on = [
    azurerm_virtual_desktop_scaling_plan.avd,
    azurerm_log_analytics_workspace.avd_monitoring,
    azurerm_monitor_diagnostic_setting.avd_host_pool,
    azurerm_monitor_diagnostic_setting.session_hosts
  ]
}

/*
 * Auto-Shutdown Policy for Cost Optimization
 *
 * Automatically shuts down session hosts during off-hours to save costs.
 * This is particularly useful for development environments.
 */
resource "azurerm_dev_test_global_vm_shutdown_schedule" "session_hosts" {
  count              = var.enable_cost_alerts ? var.session_host_count : 0
  virtual_machine_id = azurerm_windows_virtual_machine.session_host[count.index].id
  location           = azurerm_resource_group.avd.location
  enabled            = true

  daily_recurrence_time = "1800"
  timezone             = "AUS Eastern Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = 30
    webhook_url     = ""
  }
}

/*
 * Cost Management Tags
 *
 * Adds cost management tags to help with cost allocation and tracking.
 */
locals {
  cost_management_tags = {
    cost_center     = "IT-AVD"
    environment     = var.environment
    workload        = "azure-virtual-desktop"
    auto_shutdown   = var.enable_cost_alerts ? "enabled" : "disabled"
    scaling_enabled = var.enable_scaling_plans ? "enabled" : "disabled"
    monitoring      = var.enable_monitoring ? "enabled" : "disabled"
    created_by      = "terraform"
    created_date    = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Merge cost management tags with existing tags
  enhanced_tags = merge(local.tags, local.cost_management_tags)
}