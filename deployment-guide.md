# Azure Virtual Desktop Modular Deployment Guide

## Overview

This guide covers deploying **modular Azure Virtual Desktop environments** supporting four distinct deployment patterns with **Microsoft-compliant naming conventions**:

- **Pooled Desktop**: Traditional shared desktop environment (`vdpool-*-desktop`)
- **Personal Desktop**: Dedicated 1:1 desktop assignments (`vdpool-*-personal`)
- **Pooled RemoteApp**: Shared published applications (`vdpool-*-apps`)
- **Personal RemoteApp**: Dedicated application access (`vdpool-*-personalapps`)

## Microsoft Cloud Adoption Framework Naming

All resources follow [**Microsoft Cloud Adoption Framework**](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) naming standards:

### Deployment-Specific Resource Names

| Deployment Type | Host Pool Name | Application Group Name | Workspace Name |
|-----------------|----------------|------------------------|----------------|
| **Pooled Desktop** | `vdpool-avd-dev-desktop` | `vdag-avd-dev-desktop` | `vdws-avd-dev` |
| **Personal Desktop** | `vdpool-avd-dev-personal` | `vdag-avd-dev-personal` | `vdws-avd-dev` |
| **Pooled RemoteApp** | `vdpool-avd-dev-apps` | `vdag-avd-dev-apps` | `vdws-avd-dev` |
| **Personal RemoteApp** | `vdpool-avd-dev-personalapps` | `vdag-avd-dev-personalapps` | `vdws-avd-dev` |

### Network and Supporting Resources

| Resource Type | Naming Pattern | Example |
|---------------|----------------|---------|
| **Virtual Network** | `vnet-{prefix}-{environment}` | `vnet-avd-dev` |
| **Subnet** | `snet-{prefix}-{environment}` | `snet-avd-dev` |
| **Network Security Group** | `nsg-{prefix}-{environment}` | `nsg-avd-dev` |
| **Virtual Machines** | `vm-{prefix}-{environment}-{number}` | `vm-avd-dev-01` |
| **Network Interfaces** | `nic-{prefix}-{environment}-{number}` | `nic-avd-dev-01` |

## Pre-configured Deployment Options

### Quick Deployment Matrix

| Environment | Deployment Type | File | Use Case | Resulting Host Pool Name |
|-------------|----------------|------|----------|--------------------------|
| **Development** | Pooled Desktop | `dev-pooled-desktop.auto.tfvars` | Testing, training, call centers | `vdpool-avd-dev-desktop` |
| **Development** | Personal Desktop | `dev-personal-desktop.auto.tfvars` | Developer workstations | `vdpool-avd-dev-personal` |
| **Development** | Pooled RemoteApp | `dev-pooled-remoteapp.auto.tfvars` | App testing, legacy apps | `vdpool-avd-dev-apps` |
| **Production** | Personal RemoteApp | `prod-personal-remoteapp.auto.tfvars` | Executive/compliance apps | `vdpool-avd-prod-personalapps` |

### Enhanced Deployment Options (with Monitoring & Scaling)

| Environment | Deployment Type | File | Features | Use Case |
|-------------|----------------|------|----------|----------|
| **Development** | Pooled Desktop + Monitoring | `dev-pooled-desktop-with-monitoring.auto.tfvars` | Monitoring, Scaling, Dashboards | Development with cost optimization |
| **Production** | Pooled RemoteApp + Monitoring | `prod-pooled-remoteapp-with-monitoring.auto.tfvars` | Monitoring, Scaling, Dashboards | Production apps with insights |
| **Development** | Pooled Desktop + Enhanced Scaling | `dev-pooled-desktop-enhanced-scaling.auto.tfvars` | **NEW**: Built-in role with subscription scope, Advanced schedules, User notifications | Advanced development with enhanced scaling control |

## Authentication Setup

For consistent authentication across deployments, you can create a `set-auth.ps1` script to handle Azure login and context switching:

```powershell
# set-auth.ps1 - Sample Azure Authentication Script
param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "=== Azure AVD Authentication Setup ===" -ForegroundColor Green

# Login to Azure (interactive if not already logged in)
$context = az account show 2>$null | ConvertFrom-Json
if (-not $context) {
    Write-Host "Logging into Azure..." -ForegroundColor Yellow
    az login
}

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting subscription: $SubscriptionId" -ForegroundColor Cyan
    az account set --subscription $SubscriptionId
}

# Display current context
$currentContext = az account show | ConvertFrom-Json
Write-Host "✓ Authenticated as: $($currentContext.user.name)" -ForegroundColor Green
Write-Host "✓ Subscription: $($currentContext.name)" -ForegroundColor Green
Write-Host "✓ Environment: $Environment" -ForegroundColor Green

Write-Host "`nReady for Terraform deployment!" -ForegroundColor Green
```

**Usage Examples:**
```powershell
# Basic login and context check
.\set-auth.ps1

# Login with specific subscription
.\set-auth.ps1 -SubscriptionId "your-subscription-id"

# Set environment context for deployment
.\set-auth.ps1 -Environment "prod"
```

## Before You Deploy

### 1. Required Customizations

**For ALL deployment types, you MUST update:**

- **`security_principal_object_ids`** - Azure AD object IDs for users/groups who need access
- **`admin_password`** - Strong password for session host local admin (12+ chars, complexity required)

### 2. Deployment-Specific Requirements

#### For RemoteApp Deployments (`*remoteapp*` files):
- **`published_applications`** - Must define at least one application to publish
- Ensure application paths exist on the chosen VM image
- Consider custom images for line-of-business applications

#### For Personal Deployments (`personal_*` files):
- **`session_host_count`** - Should match the number of users requiring access
- Consider higher VM sizes for dedicated user resources

#### For Monitoring-Enabled Deployments (`*with-monitoring*` files):
- **`enable_monitoring`** - Set to `true` to enable comprehensive monitoring
- **`enable_scaling_plans`** - Set to `true` for cost optimization (recommended for pooled deployments)
- **`enable_dashboards`** - Set to `true` for custom insights dashboards
- **`monitoring_retention_days`** - Choose retention period (30, 60, 90, 120, 180, 365, 730 days)
- **`cost_alert_threshold`** - Set daily cost threshold for alerts

#### For Enhanced Scaling Deployments (`*enhanced-scaling*` files):
- **`scaling_plan_schedules`** - Custom schedule configuration with advanced parameters
- **`ramp_down_notification_message`** - Custom user notification messages
- **`ramp_down_wait_time_minutes`** - Configurable wait time before session termination
- **`ramp_down_force_logoff_users`** - Control whether to force logoff users
- **`ramp_down_stop_hosts_when`** - Choose when to stop hosts ("ZeroSessions", "ZeroActiveSessions")
- **Built-in Role Assignment** - Uses "Desktop Virtualization Power On Off Contributor" role at subscription scope for better permissions
- **Separate Host Pool Association** - Uses dedicated resource for better Azure Portal compatibility

### 3. Optional Customizations

- **`location`** - Change from "australiaeast" to your preferred Azure region
- **Network ranges** - Adjust to avoid conflicts with existing infrastructure
- **VM sizing** - Optimize based on workload requirements
- **Token expiration** - Adjust based on security requirements

## Getting Azure AD Object IDs

### For Users:
```powershell
# Using Azure CLI
az ad user show --id "user@domain.com" --query "id" -o tsv

# Using PowerShell
Get-AzADUser -UserPrincipalName "user@domain.com" | Select-Object Id
```

### For Groups:
```powershell
# Using Azure CLI  
az ad group show --group "AVD Users" --query "id" -o tsv

# Using PowerShell
Get-AzADGroup -DisplayName "AVD Users" | Select-Object Id
```

## Deployment Commands

### 1. Pooled Desktop (Traditional AVD)
```powershell
# Set authentication (see Authentication Setup section above)
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new dev-pooled-desktop
terraform plan -var-file=dev-pooled-desktop.auto.tfvars
terraform apply -var-file=dev-pooled-desktop.auto.tfvars
```

### 2. Personal Desktop (Dedicated VMs)
```powershell
# Set authentication (see Authentication Setup section above)
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new dev-personal-desktop
terraform plan -var-file=dev-personal-desktop.auto.tfvars
terraform apply -var-file=dev-personal-desktop.auto.tfvars
```

### 3. Pooled RemoteApp (Shared Applications)
```powershell
# Set authentication (see Authentication Setup section above)
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new dev-pooled-remoteapp
terraform plan -var-file=dev-pooled-remoteapp.auto.tfvars
terraform apply -var-file=dev-pooled-remoteapp.auto.tfvars
```

### 4. Personal RemoteApp (Dedicated App Access)
```powershell
# Set authentication (see Authentication Setup section above)
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new prod-personal-remoteapp
terraform plan -var-file=prod-personal-remoteapp.auto.tfvars
terraform apply -var-file=prod-personal-remoteapp.auto.tfvars
```

### 5. Development Pooled Desktop with Monitoring & Scaling
```powershell
# Set authentication (see Authentication Setup section above)
.\set-auth.ps1

# Initialize and deploy with monitoring
terraform init
terraform workspace new dev-pooled-desktop-monitoring
terraform plan -var-file=dev-pooled-desktop-with-monitoring.auto.tfvars
terraform apply -var-file=dev-pooled-desktop-with-monitoring.auto.tfvars
```

### 6. Production Pooled RemoteApp with Monitoring & Scaling
```powershell
# Set authentication (see Authentication Setup section above)
.\set-auth.ps1

# Initialize and deploy with monitoring
terraform init
terraform workspace new prod-pooled-remoteapp-monitoring
terraform plan -var-file=prod-pooled-remoteapp-with-monitoring.auto.tfvars
terraform apply -var-file=prod-pooled-remoteapp-with-monitoring.auto.tfvars
```

## Resource Specifications by Deployment Type

### Pooled Desktop
- **Best for**: Call centers, task workers, training environments
- **VM Size**: Standard_D4ds_v4 (4 vCPUs, 16GB RAM)
- **Sessions per Host**: 2-8 users per VM
- **Cost**: ~$150-300/month per session host

### Personal Desktop  
- **Best for**: Developers, power users, persistent workloads
- **VM Size**: Standard_D8ds_v4 (8 vCPUs, 32GB RAM)
- **Sessions per Host**: 1 user per VM (dedicated)
- **Cost**: ~$400-600/month per user

### Pooled RemoteApp
- **Best for**: Line-of-business apps, legacy applications
- **VM Size**: Standard_D4ds_v4 (4 vCPUs, 16GB RAM)
- **Sessions per Host**: 4-12 app sessions per VM
- **Cost**: ~$200-400/month per session host

### Personal RemoteApp
- **Best for**: Sensitive apps, compliance, executive access
- **VM Size**: Standard_D8ds_v4 (8 vCPUs, 32GB RAM)
- **Sessions per Host**: 1 user per VM (dedicated)
- **Cost**: ~$400-600/month per user

## Post-Deployment Verification

### 1. Azure Portal Verification
1. Navigate to **Azure Virtual Desktop → Host pools**
2. Verify your host pool appears with **Microsoft-compliant naming**:
   - Pooled Desktop: `vdpool-avd-dev-desktop`
   - Personal Desktop: `vdpool-avd-dev-personal`
   - Pooled RemoteApp: `vdpool-avd-dev-apps`
   - Personal RemoteApp: `vdpool-avd-dev-personalapps`
3. Check **Session hosts** tab for registered VMs (`vm-avd-dev-01`, `vm-avd-dev-02`, etc.)
4. Verify **Application groups** show correct Microsoft-compliant names:
   - Desktop types: `vdag-avd-dev-desktop` or `vdag-avd-dev-personal`
   - RemoteApp types: `vdag-avd-dev-apps` or `vdag-avd-dev-personalapps`

### 2. User Access Testing
1. Direct users to the [AVD web client](https://rdweb.wvd.microsoft.com/arm/webclient)
2. **Desktop deployments**: Users should see desktop icons under workspace `vdws-avd-dev`
3. **RemoteApp deployments**: Users should see published applications under workspace `vdws-avd-dev`

### 3. Configuration Verification
```powershell
# NEW: Check Microsoft-compliant naming patterns used
terraform output naming_convention

# Example output:
# {
#   "app_group_pattern" = "vdag-avd-dev-desktop"
#   "deployment_suffix" = "desktop"
#   "follows_standards" = "Microsoft Cloud Adoption Framework"
#   "host_pool_pattern" = "vdpool-avd-dev-desktop"
#   "subnet_pattern" = "snet-avd-dev"
#   "workspace_pattern" = "vdws-avd-dev"
# }

# Check deployment configuration
terraform output deployment_config

# List published applications (RemoteApp only)
terraform output published_applications

# Verify session hosts with Microsoft-compliant names
terraform output session_host_names
# Example output: ["vm-avd-dev-01", "vm-avd-dev-02"]

# Get actual resource names for portal navigation
terraform output host_pool_name        # e.g., "vdpool-avd-dev-desktop"
terraform output application_group_name # e.g., "vdag-avd-dev-desktop"
terraform output workspace_name        # e.g., "vdws-avd-dev"

# NEW: Check monitoring and scaling configuration (if enabled)
terraform output monitoring_insights

# Example output:
# {
#   "monitoring_enabled" = true
#   "scaling_enabled" = true
#   "cost_alerts_enabled" = true
#   "dashboard_enabled" = true
#   "retention_days" = 30
#   "scaling_schedules" = 2
#   "deployment_type" = "pooled_desktop"
#   "environment" = "dev"
#   "resource_group" = "rg-avd-dev"
# }

# Get quick access links
terraform output quick_links

# Check monitoring resources (if enabled)
terraform output log_analytics_workspace_name
terraform output scaling_plan_name
terraform output dashboard_name
```

## Managing Multiple Deployment Types

### Using Terraform Workspaces
```powershell
# List all workspaces
terraform workspace list

# Switch between deployment types
terraform workspace select dev-pooled-desktop
terraform workspace select dev-personal-desktop
terraform workspace select dev-pooled-remoteapp

# Show current workspace
terraform workspace show
```

### Mixed Environment Strategy
You can deploy multiple deployment types in the same subscription:

```powershell
# Deploy pooled desktop for general users
terraform workspace select pooled-users
terraform apply -var-file=prod-pooled-desktop.auto.tfvars

# Deploy personal desktops for developers  
terraform workspace select personal-devs
terraform apply -var-file=prod-personal-desktop.auto.tfvars

# Deploy RemoteApp for specific applications
terraform workspace select remoteapps
terraform apply -var-file=prod-pooled-remoteapp.auto.tfvars
```

## Monitoring and Scaling Features

### Overview

The AVD Terraform configuration now includes comprehensive monitoring, scaling, and dashboard capabilities that can be enabled for any deployment type. These features provide:

- **Cost Optimization**: Automatic scaling based on usage patterns
- **Operational Visibility**: Real-time monitoring and insights
- **Proactive Management**: Alerts and notifications
- **Performance Tracking**: Custom dashboards with key metrics

### Feature Matrix

| Feature | Description | Default | Recommended For |
|---------|-------------|---------|-----------------|
| **Monitoring** | Log Analytics workspace with diagnostic settings | Disabled | All environments |
| **Scaling Plans** | Automatic session host scaling | Disabled | Pooled deployments |
| **Cost Alerts** | Daily cost threshold monitoring | Disabled | Production environments |
| **Dashboards** | Custom Azure dashboards | Disabled | All environments |

### Scaling Plan Behavior

#### Development Environment (Default)
- **Weekdays**: Ramp-up 08:00, Peak 09:00-17:00, Ramp-down 17:00, Off-peak 18:00+
  - Minimum hosts: 20% during ramp-up/peak, 20% during ramp-down
- **Weekends**: Ramp-up 09:00, Peak 10:00-16:00, Ramp-down 16:00, Off-peak 17:00+
  - Minimum hosts: 10% during ramp-up/peak, 10% during ramp-down
- **Aggressive scaling** for maximum cost savings

#### Production Environment (Default)
- **Weekdays**: Ramp-up 07:00, Peak 08:00-18:00, Ramp-down 18:00, Off-peak 19:00+
  - Minimum hosts: 30% during ramp-up/peak, 30% during ramp-down
- **Weekends**: Ramp-up 08:00, Peak 09:00-17:00, Ramp-down 17:00, Off-peak 18:00+
  - Minimum hosts: 20% during ramp-up/peak, 20% during ramp-down
- **Conservative scaling** for reliability

**Note**: Schedules are fully customizable via `scaling_plan_schedules` variable. Enhanced scaling deployments (e.g., `dev-pooled-desktop-enhanced-scaling.auto.tfvars`) may have different schedules optimized for specific use cases.

### Monitoring Capabilities

#### Log Analytics Workspace
- **Host Pool Logs**: Connection, error, management, and registration events
- **Session Host Metrics**: CPU, memory, disk, and performance data
- **Custom Queries**: Pre-built queries for common AVD scenarios
- **Retention Options**: 30, 60, 90, 120, 180, 365, or 730 days

#### Diagnostic Settings
- **AVD Host Pool**: All AVD-specific logs and events
- **Session Host VMs**: Performance metrics and health data
- **Real-time Monitoring**: Live data streaming to Log Analytics

### Dashboard Features

#### Key Metrics Displayed
- **Session Metrics**: Active sessions, peak usage, total users
- **Performance Data**: CPU, memory, disk utilization
- **Cost Insights**: Daily/monthly costs, cost per user
- **Health Status**: Host pool, session hosts, applications
- **Scaling Status**: Last scale up/down, scaling plan health

#### Dashboard Sections
1. **Overview**: Environment and deployment information
2. **Navigation**: Quick links to Azure resources
3. **Session Metrics**: Real-time session data
4. **Performance**: Resource utilization
5. **Cost Analysis**: Spending insights
6. **Health Overview**: System status
7. **Events & Alerts**: Recent activity and notifications

### Cost Optimization

#### Scaling Plan Benefits
- **Automatic Scaling**: Session hosts scale up/down based on usage
- **Cost Savings**: 40-70% reduction in compute costs
- **User Experience**: Maintains performance during peak hours
- **Operational Efficiency**: Reduces manual scaling tasks

#### Cost Alert Features
- **Daily Thresholds**: Configurable cost limits
- **Email Notifications**: Immediate alerts when thresholds exceeded
- **Budget Tracking**: Real-time cost monitoring
- **Trend Analysis**: Historical cost patterns

### Enabling Features

#### For New Deployments
Use the monitoring-enabled `.tfvars` files:
```powershell
# Development with monitoring
terraform apply -var-file=dev-pooled-desktop-with-monitoring.auto.tfvars

# Production with monitoring
terraform apply -var-file=prod-pooled-remoteapp-with-monitoring.auto.tfvars
```

#### For Existing Deployments
Add monitoring variables to your existing `.tfvars` file:
```hcl
# Enable monitoring features
enable_monitoring = true
enable_scaling_plans = true
enable_cost_alerts = true
enable_dashboards = true

# Configure settings
monitoring_retention_days = 30
cost_alert_threshold = 100
dashboard_refresh_interval = 15
```

### Best Practices

#### Scaling Plan Configuration
- **Enable for pooled deployments** (desktop and RemoteApp)
- **Disable for personal deployments** (dedicated VMs)
- **Monitor scaling effectiveness** using dashboard metrics
- **Adjust schedules** based on actual usage patterns
- **Architecture**: Uses built-in role with subscription-level scope for broader permissions
- **Portal compatibility**: Separate host pool association resource resolves Azure Portal 404 errors

#### Monitoring Configuration
- **Use 30-day retention** for development environments
- **Use 90-day retention** for production environments
- **Enable cost alerts** for all production deployments
- **Review dashboard metrics** regularly

#### Cost Optimization
- **Set realistic cost thresholds** based on expected usage
- **Monitor scaling plan performance** monthly
- **Adjust VM sizes** based on performance data
- **Use reserved instances** for predictable workloads

## Troubleshooting

### Common Issues by Deployment Type

| Issue | Deployment Type | Solution |
|-------|----------------|----------|
| **No applications visible** | RemoteApp | Check `published_applications` configuration and app paths |
| **RemoteApp icons not showing** | RemoteApp | Fix icon_path configuration (see RemoteApp Icon Troubleshooting below) |
| **Users can't connect** | Personal | Verify sufficient session hosts for user count |
| **Poor performance** | Pooled | Reduce `max_session_limit` or increase VM size |
| **Registration fails** | All | Check registration token hasn't expired |

### RemoteApp Icon Troubleshooting

**Problem**: RemoteApp icons are not displaying in the AVD client portal.

**Root Cause**: The `icon_path` is incorrectly configured to point to the executable instead of the actual icon file.

**Solution**: Update your RemoteApp configuration with proper icon paths and icon_index:

```hcl
# INCORRECT - Using executable path as icon path without icon_index
published_applications = [
  {
    name         = "notepad"
    display_name = "Notepad"
    path         = "C:\\Windows\\System32\\notepad.exe"
    icon_path    = "C:\\Windows\\System32\\notepad.exe"  # ❌ Wrong - missing icon_index
  }
]

# CORRECT - Using executable path with icon_index parameter
published_applications = [
  {
    name         = "notepad"
    display_name = "Notepad"
    path         = "C:\\Windows\\System32\\notepad.exe"
    icon_path    = "C:\\Windows\\System32\\notepad.exe"  # ✅ Correct - executable path
    icon_index   = 0                                       # ✅ Correct - extract first icon
  },
  {
    name         = "calculator"
    display_name = "Calculator"
    path         = "C:\\Windows\\System32\\calc.exe"
    icon_path    = "C:\\Windows\\System32\\calc.exe"      # ✅ Correct - executable path
    icon_index   = 0                                       # ✅ Correct - extract first icon
  },
  {
    name         = "word"
    display_name = "Microsoft Word"
    path         = "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE"
    icon_path    = "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE"  # ✅ Correct
    icon_index   = 0                                                                   # ✅ Correct
  }
]
```

**Icon Path Best Practices**:

1. **For Windows built-in applications**: Use executable path with `icon_index = 0` to extract the first icon resource
2. **For Office applications**: Use executable path with `icon_index = 0` (Office apps have embedded icons)
3. **For custom applications**: Point to the actual `.ico` file if available
4. **For applications without icons**: Leave `icon_path` empty or omit it entirely

**Common Icon Configuration Examples**:
```hcl
# Windows built-in apps
icon_path = "C:\\Windows\\System32\\notepad.exe"
icon_index = 0

icon_path = "C:\\Windows\\System32\\calc.exe"
icon_index = 0

icon_path = "C:\\Windows\\System32\\mspaint.exe"
icon_index = 0

# Office applications
icon_path = "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE"
icon_index = 0

icon_path = "C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
icon_index = 0

icon_path = "C:\\Program Files\\Microsoft Office\\root\\Office16\\POWERPNT.EXE"
icon_index = 0

# Custom applications with .ico files
icon_path = "C:\\Program Files\\MyApp\\icon.ico"
icon_index = 0  # Not needed for .ico files, but won't hurt

# Applications without specific icons (will use default)
icon_path = ""  # or omit entirely
icon_index = 0  # Not needed when icon_path is empty
```

**Verification Steps**:
1. Update your `.tfvars` file with correct icon paths
2. Run `terraform plan` and `terraform apply` to update the configuration
3. Wait 5-10 minutes for changes to propagate
4. Check the AVD web client portal for updated icons
5. If icons still don't appear, try clearing browser cache or using incognito mode

**Additional Troubleshooting Steps**:

If icons still don't appear after applying the correct configuration:

1. **Check Application Group Type**: Ensure your application group is set to `RemoteApp` type, not `Desktop`
2. **Verify Application Paths**: Ensure the executable paths actually exist on the session host VMs
3. **Check Session Host Registration**: Verify session hosts are properly registered and healthy
4. **Test with Simple Applications**: Try with basic Windows apps first (notepad, calc) before complex applications
5. **Check Azure Portal**: Verify applications appear in Azure Portal → AVD → Application Groups → Your App Group → Applications
6. **User Permissions**: Ensure users have the correct RBAC permissions assigned
7. **Workspace Association**: Verify the application group is properly associated with the workspace

**Common Issues and Solutions**:

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Application Group Type** | Apps don't appear in client | Ensure `app_group_type = "RemoteApp"` |
| **Missing Executables** | Apps fail to launch | Verify paths exist on session host VMs |
| **Session Host Issues** | Apps show as unavailable | Check session host registration and health |
| **Permission Issues** | Users can't see apps | Verify RBAC assignments and user permissions |
| **Workspace Issues** | Apps not in user feed | Check workspace-application group association |
| **Icon Cache** | Icons don't update | Clear browser cache, wait 15-30 minutes |
| **Application State** | Apps show as disabled | Check if applications are enabled in Azure portal |

**Testing with Minimal Configuration**:

If icons still don't appear, test with this minimal configuration to isolate the issue:

```hcl
# Minimal test configuration - single application
published_applications = [
  {
    name                    = "notepad"
    display_name           = "Notepad"
    description            = "Windows Notepad"
    path                   = "C:\\Windows\\System32\\notepad.exe"
    command_line_arguments = ""
    command_line_setting   = "DoNotAllow"
    show_in_portal         = true
    icon_path             = "C:\\Windows\\System32\\notepad.exe"
    icon_index            = 0
  }
]
```

**Step-by-Step Debugging**:

1. **Deploy minimal configuration** with just one simple application (notepad)
2. **Check Azure Portal** → AVD → Application Groups → Your App Group → Applications
3. **Verify application appears** in the portal with correct icon
4. **Test user access** via AVD web client
5. **If minimal config works**, gradually add more applications
6. **If minimal config fails**, check session host registration and permissions

### Deployment Type Validation Errors

```hcl
# Error: RemoteApp deployment without applications
Error: published_applications must contain at least one application for RemoteApp deployments

# Solution: Add applications to your .tfvars file
published_applications = [
  {
    name         = "notepad"
    display_name = "Notepad"
    path         = "C:\\Windows\\System32\\notepad.exe"
    # ... other settings
  }
]
```

### Phantom Session Host Issues

If `terraform destroy` fails with session host errors:

```powershell
# Error message:
# "The SessionHostPool could not be deleted because it still has SessionHosts associated with it"

# Solution 1: Remove host pool from state and force delete resource group
terraform state rm azurerm_virtual_desktop_host_pool.avd
az group delete --name rg-avd-dev --yes --no-wait

# Solution 2: Wait and retry (Azure backend may catch up)
Start-Sleep 120  # Wait 2 minutes
terraform destroy -var-file=dev-personal-desktop.auto.tfvars

# Solution 3: Force deletion with specific types
az group delete --name rg-avd-dev --force-deletion-types Microsoft.Compute/virtualMachines,Microsoft.DesktopVirtualization/hostpools
```

**Note**: The phantom session host issue is a known Azure AVD backend problem where VM deletion doesn't always clean up session host registrations immediately.

### VM Extension Deletion Errors (VM Stopped)

If `terraform destroy` fails with extension deletion errors when VMs are stopped:

```powershell
# Error message:
# "Cannot modify extensions in the VM when the VM is not running"
# "OperationNotAllowed: Cannot modify extensions in the VM when the VM is not running"

# Solution 1: Start VMs before destroy (Recommended)
az vm start --ids $(az vm list -g rg-avd-dev --query "[].id" -o tsv)
Start-Sleep -Seconds 30  # Wait for VMs to fully start
terraform destroy -var-file=dev-pooled-desktop-enhanced-scaling.auto.tfvars

# Solution 2: Remove extensions from state and delete resource group
# This avoids extension deletion errors by removing them from Terraform state first
terraform state list | Select-String "extension" | ForEach-Object { 
    $ext = $_.ToString().Trim()
    Write-Host "Removing $ext from state..."
    terraform state rm $ext
}

# Then delete resource group directly (Azure will clean up everything automatically)
az group delete --name rg-avd-dev --yes --no-wait

# Solution 3: Remove specific extensions manually and retry
terraform state rm azurerm_virtual_machine_extension.guest_attestation[0]
terraform state rm azurerm_virtual_machine_extension.guest_attestation[1]
terraform state rm azurerm_virtual_machine_extension.avd_dsc[0]
terraform state rm azurerm_virtual_machine_extension.avd_dsc[1]
terraform state rm azurerm_virtual_machine_extension.aadlogin[0]
terraform state rm azurerm_virtual_machine_extension.aadlogin[1]

# Then retry destroy
terraform destroy -var-file=dev-pooled-desktop-enhanced-scaling.auto.tfvars
```

**Note**: Azure requires VMs to be running to modify or delete extensions. If VMs are stopped by scaling plans, auto-shutdown policies, or manual intervention, start them before running `terraform destroy`. Extensions will be automatically cleaned up when the resource group is deleted, so Solution 2 is often the fastest approach.

## Cleanup

### Remove Specific Deployment

**Important**: If VMs are stopped (due to scaling plans or auto-shutdown), extension deletion errors may occur. See [VM Extension Deletion Errors](#vm-extension-deletion-errors-vm-stopped) section for solutions.

```powershell
# Remove development pooled desktop
terraform workspace select dev-pooled-desktop
terraform destroy -var-file=dev-pooled-desktop.auto.tfvars

# Remove production RemoteApp
terraform workspace select prod-personal-remoteapp
terraform destroy -var-file=prod-personal-remoteapp.auto.tfvars
```

### Remove All Deployments
```powershell
# List and destroy all workspaces
terraform workspace list
terraform workspace select <workspace-name>
terraform destroy -var-file=<corresponding-tfvars-file>
``` 