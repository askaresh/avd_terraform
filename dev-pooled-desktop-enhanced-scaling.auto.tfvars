# Development Environment - Pooled Desktop with Enhanced Scaling
# This demonstrates the improved scaling plan capabilities with custom schedules
# Best for: Development teams requiring advanced scaling control

# Deployment Configuration
deployment_type = "pooled_desktop"
environment     = "dev"
prefix          = "avd"
location        = "australiaeast"

# Network configuration
vnet_address_space     = ["192.168.4.0/24"]
subnet_address_prefix  = "192.168.4.0/24"

# Pooled Desktop Configuration
session_host_count  = 2
max_session_limit   = 4
load_balancer_type  = "BreadthFirst"
vm_size             = "Standard_D4ds_v4"

# Image configuration
marketplace_gallery_image_sku = "win11-24h2-avd-m365"

# =============================================================================
# ENHANCED MONITORING AND SCALING CONFIGURATION
# =============================================================================

# Enable comprehensive monitoring
enable_monitoring = true
monitoring_retention_days = 30

# Enable enhanced scaling plans with custom schedules
enable_scaling_plans = true

# Custom enhanced scaling schedules with advanced configuration
scaling_plan_schedules = [
  {
    name                                 = "Weekdays"
    days_of_week                        = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                  = "07:30"
    ramp_up_load_balancing_algorithm    = "BreadthFirst"
    ramp_up_minimum_hosts_percent       = 25
    ramp_up_capacity_threshold_percent  = 75
    peak_start_time                     = "09:00"
    peak_load_balancing_algorithm       = "BreadthFirst"
    ramp_down_start_time                = "17:30"
    ramp_down_load_balancing_algorithm  = "BreadthFirst"
    ramp_down_minimum_hosts_percent     = 25
    ramp_down_capacity_threshold_percent = 25
    ramp_down_force_logoff_users        = false
    ramp_down_stop_hosts_when           = "ZeroSessions"
    ramp_down_wait_time_minutes         = 45
    ramp_down_notification_message      = "Your session will be logged off in 45 minutes due to scaling plan. Please save your work and close applications."
    off_peak_start_time                 = "19:00"
    off_peak_load_balancing_algorithm   = "BreadthFirst"
  },
  {
    name                                 = "Weekends"
    days_of_week                        = ["Saturday", "Sunday"]
    ramp_up_start_time                  = "09:00"
    ramp_up_load_balancing_algorithm    = "BreadthFirst"
    ramp_up_minimum_hosts_percent       = 10
    ramp_up_capacity_threshold_percent  = 80
    peak_start_time                     = "10:00"
    peak_load_balancing_algorithm       = "BreadthFirst"
    ramp_down_start_time                = "16:00"
    ramp_down_load_balancing_algorithm  = "BreadthFirst"
    ramp_down_minimum_hosts_percent     = 10
    ramp_down_capacity_threshold_percent = 20
    ramp_down_force_logoff_users        = false
    ramp_down_stop_hosts_when           = "ZeroSessions"
    ramp_down_wait_time_minutes         = 30
    ramp_down_notification_message      = "Your session will be logged off in 30 minutes due to scaling plan. Please save your work."
    off_peak_start_time                 = "17:00"
    off_peak_load_balancing_algorithm   = "BreadthFirst"
  },

]

# Enable cost monitoring alerts
enable_cost_alerts = true
cost_alert_threshold = 150  # Higher threshold for enhanced features

# Enable custom dashboards for insights
enable_dashboards = true
dashboard_refresh_interval = 15  # More frequent refresh for enhanced monitoring

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

# Enhanced tags with scaling indicators
tags = {
  environment      = "development"
  workload         = "azure-virtual-desktop"
  deployment_type  = "pooled-desktop"
  cost_center      = "IT-AVD"
  owner            = "dev-team"
  criticality      = "low"
  auto_shutdown    = "enabled"
  monitoring       = "enabled"
  scaling          = "enhanced"
  dashboards       = "enabled"
  created_by       = "terraform"
  scaling_version  = "enhanced"
} 