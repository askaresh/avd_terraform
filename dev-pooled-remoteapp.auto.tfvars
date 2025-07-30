# Development Environment - Pooled RemoteApp Configuration
# This publishes specific applications that users can run remotely without full desktop access
# Best for: Line-of-business apps, legacy applications, selective application access

# Deployment Configuration
deployment_type = "pooled_remoteapp"
environment     = "dev"
prefix          = "avd"
location        = "australiaeast"

# Network configuration - using default ranges for development
vnet_address_space     = ["192.168.2.0/24"]
subnet_address_prefix  = "192.168.2.0/24"

# Pooled RemoteApp Configuration
session_host_count  = 2                    # Shared session hosts for applications
max_session_limit   = 8                    # Higher session density for app-only access
load_balancer_type  = "DepthFirst"         # Fill hosts completely for app workloads
vm_size             = "Standard_D4ds_v4"   # 4 vCPUs, 16GB RAM

# Image configuration - may need apps pre-installed
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Published Applications - Define the apps users can access
published_applications = [
  {
    name                    = "calculator"
    display_name           = "Calculator"
    description            = "Windows Calculator Application"
    path                   = "C:\\Windows\\System32\\calc.exe"
    command_line_arguments = ""
    command_line_setting   = "DoNotAllow"    # Users cannot modify command line
    show_in_portal         = true
    icon_path             = "C:\\Windows\\System32\\calc.exe,0"
  },
  {
    name                    = "notepad"
    display_name           = "Notepad"
    description            = "Text Editor"
    path                   = "C:\\Windows\\System32\\notepad.exe"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Users can open specific files
    show_in_portal         = true
    icon_path             = "C:\\Windows\\System32\\notepad.exe,0"
  },
  {
    name                    = "mspaint"
    display_name           = "Paint"
    description            = "Microsoft Paint"
    path                   = "C:\\Windows\\System32\\mspaint.exe"
    command_line_arguments = ""
    command_line_setting   = "DoNotAllow"
    show_in_portal         = true
    icon_path             = "C:\\Windows\\System32\\mspaint.exe,0"
  },
  {
    name                    = "wordpad"
    display_name           = "WordPad"
    description            = "Rich Text Editor"
    path                   = "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Users can open documents
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe,0"
  }
]

# Security principals for development team access
# REQUIRED: Replace with actual Azure AD object IDs
security_principal_object_ids = [
  "01eecc64-c3bb-4c47-85ce-bafb18feef12",
  # "app-user-1-object-id",
  # "app-user-2-object-id",
]

# Local administrator credentials
admin_username = "localadmin"
# REQUIRED: Set development password
admin_password = "terraform@1234"  # Replace with actual password

# Registration token expiration - longer for development
registration_token_expiration_hours = 8  # 8 hours for dev convenience

# Development tags
tags = {
  environment      = "development"
  workload         = "azure-virtual-desktop"
  deployment_type  = "pooled-remoteapp"
  cost_center      = "IT-AVD"
  owner            = "dev-team"
  criticality      = "low"
  auto_shutdown    = "enabled"
  created_by       = "terraform"
} 