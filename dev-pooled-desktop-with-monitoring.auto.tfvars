# Development Environment - Pooled Desktop with Monitoring & Scaling
# This deploys a traditional shared desktop environment with comprehensive monitoring
# Best for: Development teams, testing environments with cost optimization

# Deployment Configuration
deployment_type = "pooled_desktop"
environment     = "dev"
prefix          = "avd"
location        = "australiaeast"

# Network configuration - using default ranges for development
vnet_address_space     = ["192.168.4.0/24"]
subnet_address_prefix  = "192.168.4.0/24"

# Pooled Desktop Configuration
session_host_count  = 2                    # Shared session hosts for development
max_session_limit   = 4                    # Moderate session density for dev
load_balancer_type  = "BreadthFirst"       # Distribute sessions evenly
vm_size             = "Standard_D4ds_v4"   # 4 vCPUs, 16GB RAM

# Image configuration - standard development image
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# =============================================================================
# MONITORING AND SCALING CONFIGURATION
# =============================================================================

# Enable comprehensive monitoring
enable_monitoring = true
monitoring_retention_days = 30

# Enable cost optimization with scaling plans
enable_scaling_plans = true

# Custom scaling schedules for development environment
# More aggressive scaling down for cost savings
scaling_plan_schedules = [
  {
    name                                 = "Weekdays"
    days_of_week                        = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                  = "08:00"
    ramp_up_load_balancing_algorithm    = "BreadthFirst"
    ramp_up_minimum_hosts_percent       = 25
    ramp_up_capacity_threshold_percent  = 80
    peak_start_time                     = "09:00"
    peak_load_balancing_algorithm       = "BreadthFirst"
    peak_minimum_hosts_percent          = 50
    ramp_down_start_time                = "17:00"
    ramp_down_load_balancing_algorithm  = "BreadthFirst"
    ramp_down_minimum_hosts_percent     = 25
    ramp_down_capacity_threshold_percent = 20
    off_peak_start_time                 = "18:00"
    off_peak_load_balancing_algorithm   = "BreadthFirst"
  },
  {
    name                                 = "Weekends"
    days_of_week                        = ["Saturday", "Sunday"]
    ramp_up_start_time                  = "10:00"
    ramp_up_load_balancing_algorithm    = "BreadthFirst"
    ramp_up_minimum_hosts_percent       = 10
    ramp_up_capacity_threshold_percent  = 80
    peak_start_time                     = "11:00"
    peak_load_balancing_algorithm       = "BreadthFirst"
    peak_minimum_hosts_percent          = 25
    ramp_down_start_time                = "15:00"
    ramp_down_load_balancing_algorithm  = "BreadthFirst"
    ramp_down_minimum_hosts_percent     = 10
    ramp_down_capacity_threshold_percent = 20
    off_peak_start_time                 = "16:00"
    off_peak_load_balancing_algorithm   = "BreadthFirst"
  }
]

# Enable cost monitoring alerts
enable_cost_alerts = true
cost_alert_threshold = 100  # Alert when monthly cost exceeds $100

# Enable custom dashboards for insights
enable_dashboards = true
dashboard_refresh_interval = 15  # Refresh every 15 minutes

# Security principals for development team access
# REQUIRED: Replace with actual Azure AD object IDs
security_principal_object_ids = [
  "01eecc64-c3bb-4c47-85ce-bafb18feef12",
  # "dev-user-1-object-id",
  # "dev-user-2-object-id",
]

# Local administrator credentials
admin_username = "localadmin"
# REQUIRED: Set development password
admin_password = "terraform@1234"  # Replace with actual password

# Registration token expiration - longer for development
registration_token_expiration_hours = 8  # 8 hours for dev convenience

# Development tags with monitoring indicators
tags = {
  environment      = "development"
  workload         = "azure-virtual-desktop"
  deployment_type  = "pooled-desktop"
  cost_center      = "IT-AVD"
  owner            = "dev-team"
  criticality      = "low"
  auto_shutdown    = "enabled"
  monitoring       = "enabled"
  scaling          = "enabled"
  dashboards       = "enabled"
  created_by       = "terraform"
} 