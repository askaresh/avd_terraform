# Development Environment Configuration for Azure Virtual Desktop
# This file contains development-specific variable overrides for testing and development work

# Environment and naming
environment = "dev"
prefix      = "avd"
location    = "australiaeast"

# Network configuration - using default ranges for development
vnet_address_space     = ["192.168.0.0/24"]
subnet_address_prefix  = "192.168.0.0/24"

# Session host configuration - minimal resources for development
vm_size             = "Standard_D4ds_v4"  # 4 vCPUs, 16GB RAM - cost-effective for dev
session_host_count  = 1                   # Single session host for development
max_session_limit   = 2                   # Lower session limit for testing

# Security principals for development team access
# REQUIRED: Replace with actual Azure AD object IDs for development team
security_principal_object_ids = [
  "01eecc64-c3bb-4c47-85ce-bafb18feef12",
  # "developer-1-object-id",
]

# Local administrator credentials
admin_username = "localadmin"
# REQUIRED: Set development password
admin_password = "terraform@1234"  # Replace with actual password

# Registration token expiration - longer for development to allow extended testing
registration_token_expiration_hours = 8  # 8 hours for dev convenience

# Development tags
tags = {
  environment   = "development"
  workload      = "azure-virtual-desktop"
  cost_center   = "IT-AVD"
  owner         = "dev-team"
  criticality   = "low"
  auto_shutdown = "enabled"
  created_by    = "terraform"
} 