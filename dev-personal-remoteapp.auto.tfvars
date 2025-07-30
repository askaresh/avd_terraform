# Development Environment - Personal RemoteApp Configuration
# This provides dedicated RemoteApp environments for testing isolated application access scenarios
# Best for: Testing dedicated app access, compliance testing, prototype development

# Deployment Configuration
deployment_type = "personal_remoteapp"
environment     = "dev"
prefix          = "avd"
location        = "australiaeast"

# Network configuration - development ranges
vnet_address_space     = ["192.168.3.0/24"]
subnet_address_prefix  = "192.168.3.0/24"

# Development Personal RemoteApp Configuration
session_host_count                 = 2                  # Small number for development testing
max_session_limit                  = 1                  # Automatically set to 1 for personal
personal_desktop_assignment_type   = "Automatic"        # Auto-assign for easy testing
vm_size                           = "Standard_D4ds_v4"  # 4 vCPUs, 16GB RAM - sufficient for dev

# Image configuration - standard development image
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# Published Applications - Development/Testing applications
published_applications = [
  {
    name                    = "visual-studio-code"
    display_name           = "Visual Studio Code"
    description            = "Lightweight code editor for development"
    path                   = "C:\\Users\\%username%\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Allow opening specific files/folders
    show_in_portal         = true
    icon_path             = "C:\\Users\\%username%\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe,0"
  },
  {
    name                    = "postman"
    display_name           = "Postman"
    description            = "API development and testing tool"
    path                   = "C:\\Users\\%username%\\AppData\\Local\\Postman\\Postman.exe"
    command_line_arguments = ""
    command_line_setting   = "DoNotAllow"
    show_in_portal         = true
    icon_path             = "C:\\Users\\%username%\\AppData\\Local\\Postman\\Postman.exe,0"
  },
  {
    name                    = "git-bash"
    display_name           = "Git Bash"
    description            = "Git command line interface"
    path                   = "C:\\Program Files\\Git\\git-bash.exe"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Allow command line for git operations
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\Git\\git-bash.exe,0"
  },
  {
    name                    = "notepad-plus-plus"
    display_name           = "Notepad++"
    description            = "Advanced text editor"
    path                   = "C:\\Program Files\\Notepad++\\notepad++.exe"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Allow opening specific files
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\Notepad++\\notepad++.exe,0"
  },
  {
    name                    = "windows-terminal"
    display_name           = "Windows Terminal"
    description            = "Modern terminal application"
    path                   = "C:\\Program Files\\WindowsApps\\Microsoft.WindowsTerminal_1.18.3181.0_x64__8wekyb3d8bbwe\\wt.exe"
    command_line_arguments = ""
    command_line_setting   = "Allow"         # Allow command line parameters
    show_in_portal         = true
    icon_path             = "C:\\Program Files\\WindowsApps\\Microsoft.WindowsTerminal_1.18.3181.0_x64__8wekyb3d8bbwe\\wt.exe,0"
  }
]

# Security principals for development team access
# REQUIRED: Replace with actual Azure AD object IDs for developers testing personal app access
security_principal_object_ids = [
  "01eecc64-c3bb-4c47-85ce-bafb18feef12",
  # "senior-developer-object-id",    # Each developer gets dedicated app access
  # "qa-engineer-object-id",
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
  deployment_type  = "personal-remoteapp"
  cost_center      = "IT-AVD"
  owner            = "dev-team"
  criticality      = "low"
  auto_shutdown    = "enabled"
  testing_purpose  = "personal-app-access"
  created_by       = "terraform"
} 