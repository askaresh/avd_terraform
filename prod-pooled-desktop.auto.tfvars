# Production Environment - Pooled Desktop Configuration
# This represents the traditional AVD deployment optimized for production workloads
# Best for: Large-scale shared desktop deployments, call centers, task workers, training environments

# Deployment Configuration
deployment_type = "pooled_desktop"
environment     = "prod"
prefix          = "avd"
location        = "australiaeast"  # Update to your preferred production region

# Network configuration - production ranges to avoid conflicts
vnet_address_space     = ["10.0.0.0/24"]
subnet_address_prefix  = "10.0.0.0/24"

# Production Pooled Desktop Configuration
session_host_count  = 4                    # Multiple session hosts for redundancy and capacity
max_session_limit   = 6                    # 6 concurrent users per session host (24 total capacity)
load_balancer_type  = "BreadthFirst"       # Distribute users evenly across all hosts
vm_size             = "Standard_D8ds_v4"   # 8 vCPUs, 32GB RAM - higher spec for production

# Image configuration - production-ready image
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Security principals for production user access
# REQUIRED: Replace with actual Azure AD object IDs for production users
security_principal_object_ids = [
  # "00000000-0000-0000-0000-000000000000",  # Production User Group 1
  # "11111111-1111-1111-1111-111111111111",  # Production User Group 2
  # "22222222-2222-2222-2222-222222222222",  # Call Center Group
  # "33333333-3333-3333-3333-333333333333",  # Training Group
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
  deployment_type  = "pooled-desktop"
  cost_center      = "IT-AVD"
  owner            = "it-operations"
  criticality      = "high"
  backup_policy    = "daily"
  patch_schedule   = "monthly"
  monitoring       = "enabled"
  scaling_policy   = "auto"
  created_by       = "terraform"
} 