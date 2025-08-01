# Production Environment - Personal RemoteApp Configuration
# This provides dedicated RemoteApp environments for users requiring isolated application access
# Best for: Sensitive applications, compliance requirements, executive access to specific tools

# Deployment Configuration
deployment_type = "personal_remoteapp"
environment     = "prod"
prefix          = "avd"
location        = "australiaeast"  # Update to your preferred production region

# Network configuration - production ranges
vnet_address_space     = ["10.2.0.0/24"]
subnet_address_prefix  = "10.2.0.0/24"

# Personal RemoteApp Configuration
session_host_count                 = 5                  # One VM per user needing dedicated app access
max_session_limit                  = 1                  # Automatically set to 1 for personal
personal_desktop_assignment_type   = "Automatic"        # Auto-assign users to VMs
vm_size                           = "Standard_D8ds_v4"  # 8 vCPUs, 32GB RAM for performance

# Image configuration - may require custom image with line-of-business apps
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Published Applications - Production line-of-business applications
published_applications = [
  {
    name                    = "financial-app"
    display_name           = "Financial Analysis Tool"
    description            = "Corporate financial analysis application"
    path                   = "C:\\Program Files\\FinancialApp\\FinApp.exe"
    command_line_arguments = "/secure"
    command_line_setting   = "Require"       # Command line required for security
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\FinancialApp\\icon.ico"
    icon_index            = 0
  },
  {
    name                    = "reporting-tool"
    display_name           = "Executive Reports"
    description            = "Management reporting dashboard"
    path                   = "C:\\Program Files\\ReportingTool\\reports.exe"
    command_line_arguments = ""
    command_line_setting   = "DoNotAllow"
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\ReportingTool\\reports.exe"
    icon_index            = 0
  },
  {
    name                    = "excel"
    display_name           = "Microsoft Excel"
    description            = "Spreadsheet application for financial modeling"
    path                   = "C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Allow opening specific files
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
    icon_index            = 0
  }
]

# Security principals that will have access to the RemoteApp applications
# REQUIRED: Replace with actual Azure AD object IDs (users requiring personal app access)
security_principal_object_ids = [
  # "00000000-0000-0000-0000-000000000000",  # Finance Director
  # "11111111-1111-1111-1111-111111111111",  # CFO
  # "22222222-2222-2222-2222-222222222222",  # Financial Analyst 1
  # "33333333-3333-3333-3333-333333333333",  # Financial Analyst 2
  # "44444444-4444-4444-4444-444444444444",  # Executive Assistant
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
  deployment_type  = "personal-remoteapp"
  cost_center      = "IT-AVD"
  owner            = "it-operations"
  criticality      = "high"
  backup_policy    = "daily"
  patch_schedule   = "monthly"
  compliance       = "required"
  created_by       = "terraform"
} 