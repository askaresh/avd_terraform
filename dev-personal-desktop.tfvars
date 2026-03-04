# Development Environment - Personal Desktop Configuration  
# This provides dedicated 1:1 desktop assignments for users who need persistent environments
# Best for: Power users, developers, users requiring dedicated resources

# Deployment Configuration
deployment_type = "personal_desktop"
environment     = "dev"
prefix          = "avd"
location        = "australiaeast"

# Network configuration - using default ranges for development
vnet_address_space     = ["192.168.1.0/24"]
subnet_address_prefix  = "192.168.1.0/24"

# Personal Desktop Configuration
session_host_count                 = 2                  # One VM per user (3 developers)
max_session_limit                  = 1                  # Automatically set to 1 for personal
personal_desktop_assignment_type   = "Automatic"        # Auto-assign users to available VMs
vm_size                           = "Standard_D4ds_v4"  # 4 vCPUs, 16GB RAM - fits quota (3×4=12 cores)

# Image configuration
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Security principals for development team access
# REQUIRED: Replace with actual Azure AD object IDs for users needing personal desktops
security_principal_object_ids = [
  "01eecc64-c3bb-4c47-85ce-bafb18feef12",
  # "developer-1-object-id",    # Each user gets their own dedicated VM
  # "developer-2-object-id",
  # "developer-3-object-id",
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
  deployment_type  = "personal-desktop"
  cost_center      = "IT-AVD"
  owner            = "dev-team"
  criticality      = "medium"  # Higher than pooled due to dedicated resources
  auto_shutdown    = "enabled"
  created_by       = "terraform"
} 