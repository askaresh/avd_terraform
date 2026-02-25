# Azure Authentication for Terraform
# Run this script before executing terraform commands
# Usage: .\set-auth.ps1
#
# Prerequisites:
#   Create a .env file in the same directory with the following content:
#   ARM_CLIENT_ID=<your-client-id>
#   ARM_CLIENT_SECRET=<your-client-secret>
#   ARM_TENANT_ID=<your-tenant-id>
#   ARM_SUBSCRIPTION_ID=<your-subscription-id>

$ErrorActionPreference = 'Stop'

Write-Host "Loading Azure authentication from .env file..." -ForegroundColor Green

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".env"

# Check if .env file exists
if (-not (Test-Path $EnvFile)) {
    Write-Host "ERROR: .env file not found at: $EnvFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please create a .env file with the following content:" -ForegroundColor Yellow
    Write-Host "  ARM_CLIENT_ID=<your-client-id>" -ForegroundColor Cyan
    Write-Host "  ARM_CLIENT_SECRET=<your-client-secret>" -ForegroundColor Cyan
    Write-Host "  ARM_TENANT_ID=<your-tenant-id>" -ForegroundColor Cyan
    Write-Host "  ARM_SUBSCRIPTION_ID=<your-subscription-id>" -ForegroundColor Cyan
    exit 1
}

# Read and parse .env file
Get-Content $EnvFile | ForEach-Object {
    # Skip empty lines and comments
    if ($_ -match '^\s*$' -or $_ -match '^\s*#') {
        return
    }
    
    # Parse KEY=VALUE format
    if ($_ -match '^([^=]+)=(.*)$') {
        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        
        # Set environment variable
        Set-Item -Path "Env:$key" -Value $value
        Write-Host "  Set: $key" -ForegroundColor Gray
    }
}

# Validate required variables
$RequiredVars = @('ARM_CLIENT_ID', 'ARM_CLIENT_SECRET', 'ARM_TENANT_ID', 'ARM_SUBSCRIPTION_ID')
$MissingVars = @()

foreach ($var in $RequiredVars) {
    if (-not (Get-Item -Path "Env:$var" -ErrorAction SilentlyContinue)) {
        $MissingVars += $var
    }
}

if ($MissingVars.Count -gt 0) {
    Write-Host "ERROR: Missing required environment variables:" -ForegroundColor Red
    $MissingVars | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host ""
Write-Host "Environment variables set successfully!" -ForegroundColor Green
Write-Host "Subscription: $env:ARM_SUBSCRIPTION_ID" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now run: terraform init, terraform plan, terraform apply" -ForegroundColor Yellow 