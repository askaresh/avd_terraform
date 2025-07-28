# Azure Virtual Desktop Modular Deployment Guide

## Overview

This guide covers deploying **modular Azure Virtual Desktop environments** supporting four distinct deployment patterns:

- **Pooled Desktop**: Traditional shared desktop environment
- **Personal Desktop**: Dedicated 1:1 desktop assignments  
- **Pooled RemoteApp**: Shared published applications
- **Personal RemoteApp**: Dedicated application access

## Pre-configured Deployment Options

### Quick Deployment Matrix

| Environment | Deployment Type | File | Use Case |
|-------------|----------------|------|----------|
| **Development** | Pooled Desktop | `dev-pooled-desktop.auto.tfvars` | Testing, training, call centers |
| **Development** | Personal Desktop | `dev-personal-desktop.auto.tfvars` | Developer workstations |
| **Development** | Pooled RemoteApp | `dev-pooled-remoteapp.auto.tfvars` | App testing, legacy apps |
| **Production** | Personal RemoteApp | `prod-personal-remoteapp.auto.tfvars` | Executive/compliance apps |

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
# Set authentication
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new dev-pooled-desktop
terraform plan -var-file=dev-pooled-desktop.auto.tfvars
terraform apply -var-file=dev-pooled-desktop.auto.tfvars
```

### 2. Personal Desktop (Dedicated VMs)
```powershell
# Set authentication
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new dev-personal-desktop
terraform plan -var-file=dev-personal-desktop.auto.tfvars
terraform apply -var-file=dev-personal-desktop.auto.tfvars
```

### 3. Pooled RemoteApp (Shared Applications)
```powershell
# Set authentication
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new dev-pooled-remoteapp
terraform plan -var-file=dev-pooled-remoteapp.auto.tfvars
terraform apply -var-file=dev-pooled-remoteapp.auto.tfvars
```

### 4. Personal RemoteApp (Dedicated App Access)
```powershell
# Set authentication
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new prod-personal-remoteapp
terraform plan -var-file=prod-personal-remoteapp.auto.tfvars
terraform apply -var-file=prod-personal-remoteapp.auto.tfvars
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
2. Verify your host pool appears with correct type (Pooled/Personal)
3. Check **Session hosts** tab for registered VMs
4. Verify **Application groups** show correct type (Desktop/RemoteApp)

### 2. User Access Testing
1. Direct users to the [AVD web client](https://rdweb.wvd.microsoft.com/arm/webclient)
2. **Desktop deployments**: Users should see desktop icons
3. **RemoteApp deployments**: Users should see published applications

### 3. Configuration Verification
```powershell
# Check deployment configuration
terraform output deployment_config

# List published applications (RemoteApp only)
terraform output published_applications

# Verify session hosts
terraform output session_host_names
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

## Troubleshooting

### Common Issues by Deployment Type

| Issue | Deployment Type | Solution |
|-------|----------------|----------|
| **No applications visible** | RemoteApp | Check `published_applications` configuration and app paths |
| **Users can't connect** | Personal | Verify sufficient session hosts for user count |
| **Poor performance** | Pooled | Reduce `max_session_limit` or increase VM size |
| **Registration fails** | All | Check registration token hasn't expired |

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

## Cleanup

### Remove Specific Deployment
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