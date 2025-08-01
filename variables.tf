/**
* Variables used to parameterise the Azure Virtual Desktop deployment.  Each
* variable includes a description and sensible defaults where appropriate.
* Users should override these values in a `terraform.tfvars` file or via
* environment specific variable files when deploying to different
* environments (for example `dev.auto.tfvars` and `prod.auto.tfvars`).
*/

variable "location" {
  description = "Azure region in which to deploy all resources.  Choose a region close to your users to minimise latency."
  type        = string
  default     = "australiaeast"
}

variable "prefix" {
  description = "Short prefix used to build resource names.  Use lowercase letters and numbers only."
  type        = string
  default     = "avd"
}

variable "environment" {
  description = "Environment name (for example 'dev', 'test', 'prod').  This value is appended to resource names to separate environments."
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network.  Must be an RFC1918 CIDR block."
  type        = list(string)
  default     = ["192.168.0.0/24"]
}

variable "subnet_address_prefix" {
  description = "CIDR prefix used for the subnet that session hosts will reside in.  Must fall within the virtual network address space."
  type        = string
  default     = "192.168.0.0/24"
}

variable "vm_size" {
  description = "Azure VM size used for the session hosts.  Choose an SKU that supports Windows 11 Enterprise Multi‑Session and Trusted Launch."
  type        = string
  default     = "Standard_D4ds_v4"
}

variable "marketplace_gallery_image_sku" {
  description = "Marketplace image SKU for the session host.  The default points at Windows 11 Enterprise multi‑session with Microsoft 365 Apps."
  type        = string
  default     = "win11-24h2-avd-m365"
}

variable "configuration_zip_file" {
  description = "URL of the AVD DSC configuration zip file used to register session hosts.  The zip file must contain the AddSessionHost configuration."
  type        = string
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02790.438.zip"
}

variable "security_principal_object_ids" {
  description = "List of Azure AD object IDs (users, groups or service principals) that should be assigned to the Desktop Application Group and allowed to log onto session hosts."
  type        = list(string)
  default     = []
}

variable "admin_username" {
  description = "Local administrator user name for the session host VMs."
  type        = string
  default     = "localadmin"
}

variable "admin_password" {
  description = "Local administrator password for the session host VMs.  Marked as sensitive so it is not displayed in Terraform output."
  type        = string
  sensitive   = true
}

variable "max_session_limit" {
  description = "Maximum number of concurrent user sessions per session host."
  type        = number
  default     = 2
}

variable "session_host_count" {
  description = "Number of session host virtual machines to deploy in the host pool."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags to apply to all resources.  These tags are merged with standard tags defined in locals."
  type        = map(string)
  default     = {}
}

variable "registration_token_expiration_hours" {
  description = "Number of hours from deployment time when the host pool registration token expires. Use longer duration for dev environments (8-24h), shorter for production (1-2h) for better security."
  type        = number
  default     = 2
}

variable "deployment_type" {
  description = "AVD deployment type: pooled_desktop (traditional shared desktops), personal_desktop (dedicated 1:1 desktops), pooled_remoteapp (shared published applications), personal_remoteapp (dedicated published applications)"
  type        = string
  validation {
    condition = contains([
      "pooled_desktop",
      "personal_desktop", 
      "pooled_remoteapp",
      "personal_remoteapp"
    ], var.deployment_type)
    error_message = "Must be one of: pooled_desktop, personal_desktop, pooled_remoteapp, personal_remoteapp"
  }
  default = "pooled_desktop"
}

variable "load_balancer_type" {
  description = "Load balancing algorithm for pooled host pools. BreadthFirst distributes users across all hosts before filling any host. DepthFirst fills each host to capacity before moving to the next."
  type        = string
  validation {
    condition     = contains(["BreadthFirst", "DepthFirst"], var.load_balancer_type)
    error_message = "Must be BreadthFirst or DepthFirst"
  }
  default = "BreadthFirst"
}

variable "personal_desktop_assignment_type" {
  description = "Assignment type for personal desktop host pools. Automatic assigns users to any available VM. Direct requires specific VM assignment."
  type        = string
  validation {
    condition     = contains(["Automatic", "Direct"], var.personal_desktop_assignment_type)
    error_message = "Must be Automatic or Direct"
  }
  default = "Automatic"
}

variable "published_applications" {
  description = "List of applications to publish for RemoteApp deployments. Each application defines an executable that users can launch remotely."
  type = list(object({
    name                         = string
    display_name                = string
    description                 = optional(string, "")
    path                        = string
    command_line_arguments      = optional(string, "")
    command_line_setting        = optional(string, "DoNotAllow")
    show_in_portal             = optional(bool, true)
    icon_path                  = optional(string, "")
    icon_index                 = optional(number, 0)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for app in var.published_applications : 
      contains(["Allow", "DoNotAllow", "Require"], app.command_line_setting)
    ])
    error_message = "command_line_setting must be Allow, DoNotAllow, or Require for each application"
  }
}

# =============================================================================
# SCALING PLANS CONFIGURATION
# =============================================================================

variable "enable_scaling_plans" {
  description = "Enable automatic scaling plans for cost optimization. Recommended for pooled deployments (pooled_desktop, pooled_remoteapp)."
  type        = bool
  default     = false
}

variable "scaling_plan_schedules" {
  description = "Custom scaling schedules for AVD host pool. If empty, uses default schedules based on environment."
  type = list(object({
    name                                 = string
    days_of_week                        = list(string)
    ramp_up_start_time                  = string
    ramp_up_load_balancing_algorithm    = string
    ramp_up_minimum_hosts_percent       = number
    ramp_up_capacity_threshold_percent  = number
    peak_start_time                     = string
    peak_load_balancing_algorithm       = string
    ramp_down_start_time                = string
    ramp_down_load_balancing_algorithm  = string
    ramp_down_minimum_hosts_percent     = number
    ramp_down_capacity_threshold_percent = number
    ramp_down_force_logoff_users        = bool
    ramp_down_stop_hosts_when           = string
    ramp_down_wait_time_minutes         = number
    ramp_down_notification_message      = string
    off_peak_start_time                 = string
    off_peak_load_balancing_algorithm   = string
  }))
  default = []
}

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

variable "enable_monitoring" {
  description = "Enable comprehensive monitoring for AVD resources including host pools, session hosts, and usage metrics."
  type        = bool
  default     = false
}

variable "monitoring_retention_days" {
  description = "Log retention period in days for monitoring data. Options: 30, 60, 90, 120, 180, 365, 730."
  type        = number
  default     = 30
  
  validation {
    condition = contains([30, 60, 90, 120, 180, 365, 730], var.monitoring_retention_days)
    error_message = "Retention days must be one of: 30, 60, 90, 120, 180, 365, 730"
  }
}

variable "enable_cost_alerts" {
  description = "Enable cost monitoring alerts for AVD resource consumption and budget tracking."
  type        = bool
  default     = false
}

variable "cost_alert_threshold" {
  description = "Cost alert threshold in USD. Alerts will be triggered when daily cost exceeds this amount."
  type        = number
  default     = 100
}

# =============================================================================
# DASHBOARD CONFIGURATION
# =============================================================================

variable "enable_dashboards" {
  description = "Enable custom Azure dashboards for AVD insights and monitoring."
  type        = bool
  default     = false
}

variable "dashboard_refresh_interval" {
  description = "Dashboard refresh interval in minutes. Options: 5, 15, 30, 60."
  type        = number
  default     = 15
  
  validation {
    condition = contains([5, 15, 30, 60], var.dashboard_refresh_interval)
    error_message = "Refresh interval must be one of: 5, 15, 30, 60"
  }
}

