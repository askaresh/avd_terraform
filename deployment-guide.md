# Quick Deployment Guide

## Before You Deploy

### 1. Required Customizations

**For both `dev.auto.tfvars` and `prod.auto.tfvars`, you MUST update:**

- **`security_principal_object_ids`** - Azure AD object IDs for users/groups who need access
- **`admin_password`** - Strong password for session host local admin (12+ chars, complexity required)

### 2. Optional Customizations

- **`location`** - Change from "australiaeast" to your preferred Azure region
- **Network ranges** - Adjust `vnet_address_space` and `subnet_address_prefix` to avoid conflicts
- **Resource sizes** - Modify `vm_size`, `session_host_count`, `max_session_limit` as needed
- **Token expiration** - Adjust `registration_token_expiration_hours` (8h for dev, 1h for prod)

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

### Development Environment:
```powershell
# Set authentication
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new dev
terraform plan -var-file=dev.auto.tfvars
terraform apply -var-file=dev.auto.tfvars
```

### Production Environment:
```powershell
# Set authentication  
.\set-auth.ps1

# Initialize and deploy
terraform init
terraform workspace new prod
terraform plan -var-file=prod.auto.tfvars
terraform apply -var-file=prod.auto.tfvars
```

## Resource Specifications

### Development (dev.auto.tfvars):
- **VM Size:** Standard_D4ds_v4 (4 vCPUs, 16GB RAM)
- **Session Hosts:** 1 
- **Max Sessions:** 2 per host
- **Cost:** ~$150-200/month (estimate)

### Production (prod.auto.tfvars):
- **VM Size:** Standard_D8ds_v4 (8 vCPUs, 32GB RAM) 
- **Session Hosts:** 3
- **Max Sessions:** 8 per host
- **Cost:** ~$800-1000/month (estimate)

## Post-Deployment

1. Verify resources in Azure portal: **Azure Virtual Desktop → Host pools**
2. Test user access via the [AVD web client](https://rdweb.wvd.microsoft.com/arm/webclient)
3. Monitor performance and adjust session limits as needed

## Cleanup

```powershell
# Remove development environment
terraform workspace select dev
terraform destroy -var-file=dev.auto.tfvars

# Remove production environment  
terraform workspace select prod
terraform destroy -var-file=prod.auto.tfvars
``` 