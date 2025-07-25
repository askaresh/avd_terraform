# Production Environment Configuration for Azure Virtual Desktop
# This file contains production-specific variable overrides
# 
# REQUIRED: Update the following values before deployment:
# - security_principal_object_ids: Add actual Azure AD object IDs
# - admin_password: Set a strong password for session hosts
# - location: Verify the Azure region is appropriate for your users
# - Network ranges: Adjust if they conflict with existing infrastructure

# Environment and naming
environment = "prod"
prefix      = "avd"
location    = "australiaeast"  # Update to your preferred production region

# Network configuration - adjust these ranges to fit your network architecture
vnet_address_space     = ["10.1.0.0/24"]
subnet_address_prefix  = "10.1.0.0/24"

# Session host configuration - optimized for production workloads
vm_size             = "Standard_D8ds_v4"  # 8 vCPUs, 32GB RAM for better performance
session_host_count  = 3                   # Deploy 3 session hosts for redundancy
max_session_limit   = 8                   # Higher concurrent sessions per host

# Security principals that will have access to the desktop
# REQUIRED: Replace with actual Azure AD object IDs (users, groups, or service principals)
security_principal_object_ids = [
  # "00000000-0000-0000-0000-000000000000",  # Example user/group ID
  # "11111111-1111-1111-1111-111111111111",  # Example user/group ID
]

# Local administrator credentials for session hosts
admin_username = "localadmin"
# REQUIRED: Set a strong password - minimum 12 characters with complexity requirements
admin_password = ""  # Replace with actual password

# Registration token expiration - shorter for production security
registration_token_expiration_hours = 1  # 1 hour for enhanced security

# Production tags for governance and cost management
tags = {
  environment    = "production"
  workload       = "azure-virtual-desktop"
  cost_center    = "IT-AVD"
  owner          = "it-operations"
  criticality    = "high"
  backup_policy  = "daily"
  patch_schedule = "monthly"
  created_by     = "terraform"
} 