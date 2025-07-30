# Production Environment - Personal Desktop Configuration
# This provides dedicated 1:1 desktop assignments for production users requiring persistent environments
# Best for: Executives, power users, developers, users requiring dedicated high-performance resources

# Deployment Configuration
deployment_type = "personal_desktop"
environment     = "prod"
prefix          = "avd"
location        = "australiaeast"  # Update to your preferred production region

# Network configuration - production ranges
vnet_address_space     = ["10.1.0.0/24"]
subnet_address_prefix  = "10.1.0.0/24"

# Production Personal Desktop Configuration
session_host_count                 = 10                 # 10 dedicated VMs for 10 power users
max_session_limit                  = 1                  # Automatically set to 1 for personal
personal_desktop_assignment_type   = "Automatic"        # Auto-assign users to available VMs
vm_size                           = "Standard_D16ds_v4" # 16 vCPUs, 64GB RAM - premium resources

# Image configuration - high-performance image for power users
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Security principals for production personal desktop access
# REQUIRED: Replace with actual Azure AD object IDs for users requiring dedicated desktops
security_principal_object_ids = [
  # "00000000-0000-0000-0000-000000000000",  # Executive 1
  # "11111111-1111-1111-1111-111111111111",  # Executive 2
  # "22222222-2222-2222-2222-222222222222",  # Senior Developer 1
  # "33333333-3333-3333-3333-333333333333",  # Senior Developer 2
  # "44444444-4444-4444-4444-444444444444",  # Data Analyst 1
  # "55555555-5555-5555-5555-555555555555",  # Data Analyst 2
  # "66666666-6666-6666-6666-666666666666",  # Power User 1
  # "77777777-7777-7777-7777-777777777777",  # Power User 2
  # "88888888-8888-8888-8888-888888888888",  # Power User 3
  # "99999999-9999-9999-9999-999999999999",  # Power User 4
]

# Local administrator credentials for session hosts
admin_username = "localadmin"
# REQUIRED: Set a strong password - minimum 12 characters with complexity requirements
admin_password = ""  # Replace with actual password

# Registration token expiration - shorter for production security
registration_token_expiration_hours = 1  # 1 hour for enhanced security

# Production tags for governance and cost management
tags = {
  environment      = "production"
  workload         = "azure-virtual-desktop"
  deployment_type  = "personal-desktop"
  cost_center      = "IT-AVD"
  owner            = "it-operations"
  criticality      = "high"
  backup_policy    = "daily"
  patch_schedule   = "monthly"
  monitoring       = "enabled"
  performance_tier = "premium"
  created_by       = "terraform"
} 