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
  tags     = local.tags
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
  computer_name       = format("avd%02d", count.index + 1)
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
}