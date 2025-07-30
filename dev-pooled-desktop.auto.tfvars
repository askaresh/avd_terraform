# Development Environment - Pooled Desktop Configuration
# This represents the traditional AVD deployment where multiple users share session hosts
# Best for: Cost-effective multi-user environments, call centers, task workers

# Deployment Configuration
deployment_type = "pooled_desktop"
environment     = "dev"
prefix          = "avd"
location        = "australiaeast"

# Network configuration - using default ranges for development
vnet_address_space     = ["192.168.0.0/24"]
subnet_address_prefix  = "192.168.0.0/24"

# Pooled Desktop Configuration
session_host_count  = 2                    # Multiple users per host
max_session_limit   = 4                    # 4 concurrent users per session host
load_balancer_type  = "BreadthFirst"       # Distribute users across all hosts first
vm_size             = "Standard_D4ds_v4"   # 4 vCPUs, 16GB RAM - good for pooled scenarios

# Image configuration
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Security principals for development team access
# REQUIRED: Replace with actual Azure AD object IDs for development team
security_principal_object_ids = [
  "01eecc64-c3bb-4c47-85ce-bafb18feef12",
  # "developer-1-object-id",
  # "developer-2-object-id",
]

# Local administrator credentials
admin_username = "localadmin"
# REQUIRED: Set development password
admin_password = "terraform@1234"  # Replace with actual password

# Registration token expiration - longer for development to allow extended testing
registration_token_expiration_hours = 8  # 8 hours for dev convenience

# Development tags
tags = {
  environment      = "development"
  workload         = "azure-virtual-desktop"
  deployment_type  = "pooled-desktop"
  cost_center      = "IT-AVD"
  owner            = "dev-team"
  criticality      = "low"
  auto_shutdown    = "enabled"
  created_by       = "terraform"
} 