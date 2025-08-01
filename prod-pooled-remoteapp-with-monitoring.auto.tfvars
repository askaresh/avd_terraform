# Production Environment - Pooled RemoteApp with Monitoring & Scaling
# This deploys shared published applications with comprehensive monitoring
# Best for: Enterprise applications, legacy systems with cost optimization

# Deployment Configuration
deployment_type = "pooled_remoteapp"
environment     = "prod"
prefix          = "avd"
location        = "australiaeast"

# Network configuration - production ranges
vnet_address_space     = ["10.3.0.0/24"]
subnet_address_prefix  = "10.3.0.0/24"

# Production Pooled RemoteApp Configuration
session_host_count  = 3                    # Multiple hosts for high availability
max_session_limit   = 12                   # Higher session density for production efficiency
load_balancer_type  = "DepthFirst"         # Fill hosts completely for app workloads
vm_size             = "Standard_D8ds_v4"   # 8 vCPUs, 32GB RAM - optimized for apps

# Image configuration - may require custom image with pre-installed line-of-business apps
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Published Applications - Production line-of-business applications
published_applications = [
  {
    name                    = "sap-gui"
    display_name           = "SAP GUI"
    description            = "SAP Enterprise Resource Planning"
    path                   = "C:\\Program Files (x86)\\SAP\\FrontEnd\\SAPgui\\saplogon.exe"
    command_line_arguments = ""
    command_line_setting   = "DoNotAllow"    # Secure - no command line modification
    show_in_portal         = true
    icon_path             = "C:\\Program Files (x86)\\SAP\\FrontEnd\\SAPgui\\saplogon.ico"
    icon_index            = 0
  },
  {
    name                    = "excel"
    display_name           = "Microsoft Excel"
    description            = "Advanced spreadsheet application for business analytics"
    path                   = "C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Allow opening specific files
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
    icon_index            = 0
  },
  {
    name                    = "powerbi-desktop"
    display_name           = "Power BI Desktop"
    description            = "Business analytics and reporting tool"
    path                   = "C:\\Program Files\\Microsoft Power BI Desktop\\bin\\PBIDesktop.exe"
    command_line_arguments = ""
    command_line_setting   = "Allow"
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\Microsoft Power BI Desktop\\bin\\PBIDesktop.exe"
    icon_index            = 0
  }
]

# =============================================================================
# MONITORING AND SCALING CONFIGURATION
# =============================================================================

# Enable comprehensive monitoring
enable_monitoring = true
monitoring_retention_days = 90  # Longer retention for production

# Enable cost optimization with scaling plans
enable_scaling_plans = true
# Note: Uses production-optimized scaling schedules by default

# Enable cost monitoring alerts
enable_cost_alerts = true
cost_alert_threshold = 200  # Alert when daily cost exceeds $200

# Enable custom dashboards for insights
enable_dashboards = true
dashboard_refresh_interval = 5  # More frequent refresh for production

# Security principals for production RemoteApp access
# REQUIRED: Replace with actual Azure AD object IDs for users requiring application access
security_principal_object_ids = [
  # "00000000-0000-0000-0000-000000000000",  # Business Analysts Group
  # "11111111-1111-1111-1111-111111111111",  # Finance Team
  # "22222222-2222-2222-2222-222222222222",  # Engineering Group
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
  deployment_type  = "pooled-remoteapp"
  cost_center      = "IT-AVD"
  owner            = "it-operations"
  criticality      = "high"
  backup_policy    = "daily"
  patch_schedule   = "monthly"
  monitoring       = "enabled"
  scaling          = "enabled"
  dashboards       = "enabled"
  app_licensing    = "enterprise"
  created_by       = "terraform"
} 