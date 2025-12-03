# 🔄 AVD Terraform Dependency Flow Analysis

## 📋 **Complete Deployment Order & Dependencies**

### **Phase 1: Foundation Resources**
```
1. Resource Group (azurerm_resource_group.avd)
   ↓
2. Network Infrastructure
   ├── Virtual Network (azurerm_virtual_network.avd)
   ├── Subnet (azurerm_subnet.avd)
   └── Network Security Group (azurerm_network_security_group.avd)
   ↓
3. AVD Core Infrastructure
   ├── Host Pool (azurerm_virtual_desktop_host_pool.avd)
   ├── Application Group (azurerm_virtual_desktop_application_group.avd)
   └── Workspace (azurerm_virtual_desktop_workspace.avd)
```

### **Phase 2: Session Hosts & Extensions**
```
4. Session Host Infrastructure
   ├── Network Interfaces (azurerm_network_interface.session_host)
   ├── Virtual Machines (azurerm_windows_virtual_machine.session_host)
   └── VM Extensions
       ├── Guest Attestation
       ├── DSC (AVD Registration)
       └── AAD Login
```

### **Phase 3: Monitoring & Scaling Foundation**
```
5. Monitoring Infrastructure
   └── Log Analytics Workspace (azurerm_log_analytics_workspace.avd_monitoring)
   ↓
6. Scaling Plan Prerequisites
   ├── Subscription Data (data.azurerm_subscription.current)
   ├── Random UUID (random_uuid.scaling_plan_role)
   ├── Role Definition (data.azurerm_role_definition.avd_power_role) - Built-in role
   ├── Service Principal (data.azuread_service_principal.avd) - Hardcoded client ID
   └── Role Assignment (azurerm_role_assignment.scaling_plan) - Subscription scope
```

### **Phase 4: Scaling Plan & Advanced Features**
```
7. Scaling Plan (azurerm_virtual_desktop_scaling_plan.avd)
   ↓
8. Host Pool Association (azurerm_virtual_desktop_scaling_plan_host_pool_association.avd)
   ↓
9. Monitoring & Cost Management
   ├── Diagnostic Settings
   │   ├── Host Pool Diagnostics
   │   └── Session Host Diagnostics
   ├── Cost Alerts
   │   ├── Action Group
   │   └── Consumption Budget
   ├── Dashboard (azurerm_portal_dashboard.avd_insights)
   └── Auto-Shutdown Schedules
```

## 🔗 **Explicit Dependencies**

### **Scaling Plan Dependencies**
```hcl
resource "azurerm_virtual_desktop_scaling_plan" "avd" {
  # ... configuration ...
  
  # Host pool association handled separately (see below)
  # This ensures better Azure Portal compatibility
  
  depends_on = [
    azurerm_role_assignment.scaling_plan,                    # ← Role must be assigned first
    azurerm_virtual_desktop_host_pool.avd,                   # ← Host pool must exist
    azurerm_windows_virtual_machine.session_host             # ← Session hosts must be ready
  ]
}

# Separate host pool association resource (best practice)
resource "azurerm_virtual_desktop_scaling_plan_host_pool_association" "avd" {
  host_pool_id    = azurerm_virtual_desktop_host_pool.avd.id  # ← Implicit dependency
  scaling_plan_id = azurerm_virtual_desktop_scaling_plan.avd[0].id
  enabled         = true
  
  depends_on = [
    azurerm_virtual_desktop_scaling_plan.avd,
    azurerm_role_assignment.scaling_plan
  ]
}
```

### **Dashboard Dependencies**
```hcl
resource "azurerm_portal_dashboard" "avd_insights" {
  # ... configuration ...
  
  depends_on = [
    azurerm_virtual_desktop_scaling_plan.avd,                # ← Scaling plan must exist
    azurerm_log_analytics_workspace.avd_monitoring,          # ← Workspace must exist
    azurerm_monitor_diagnostic_setting.avd_host_pool,        # ← Diagnostics must be configured
    azurerm_monitor_diagnostic_setting.session_hosts         # ← Session host diagnostics ready
  ]
}
```

## 🎯 **Dynamic Configuration Flow**

### **How Scaling Plan Gets All Required Information:**

1. **Host Pool ID**: Automatically retrieved from `azurerm_virtual_desktop_host_pool.avd.id` and associated via separate `azurerm_virtual_desktop_scaling_plan_host_pool_association` resource
2. **Session Host Count**: Uses `var.session_host_count` for scaling calculations
3. **Resource Group**: References `azurerm_resource_group.avd.name` and `.location`
4. **Role Assignment**: Uses subscription-level scope with built-in "Desktop Virtualization Power On Off Contributor" role
5. **Service Principal**: Uses hardcoded AVD service principal client ID (`9cdead84-a844-4324-93f2-b2e6bb768d07`) for reliability
6. **Scaling Schedules**: Uses `local.scaling_schedules` which are dynamically generated based on:
   - `var.environment` (dev/prod)
   - `var.scaling_plan_schedules` (custom schedules if provided)
   - Default schedules if no custom ones specified

### **How Monitoring Resources Get Configuration:**

1. **Log Analytics Workspace ID**: Automatically retrieved from `azurerm_log_analytics_workspace.avd_monitoring[0].id`
2. **Host Pool ID**: References `azurerm_virtual_desktop_host_pool.avd.id`
3. **Session Host IDs**: Uses `azurerm_windows_virtual_machine.session_host[count.index].id`
4. **Resource Group**: References `azurerm_resource_group.avd.name`

## ✅ **Verification Points**

### **Scaling Plan Validation**
- ✅ Host pool exists and is properly configured
- ✅ Session hosts are deployed and registered
- ✅ Role assignment is in place (subscription-level scope)
- ✅ Built-in role "Desktop Virtualization Power On Off Contributor" is assigned
- ✅ Host pool association resource exists
- ✅ Scaling schedules are properly formatted
- ✅ Random UUID generated for role assignment name

### **Monitoring Validation**
- ✅ Log Analytics workspace is created
- ✅ Diagnostic settings are configured
- ✅ Dashboard has access to all required resources
- ✅ Cost monitoring is properly set up

## 🚀 **Benefits of This Approach**

1. **Automatic Dependency Resolution**: Terraform automatically resolves implicit dependencies
2. **Explicit Control**: `depends_on` ensures critical resources are created first
3. **Dynamic Configuration**: All resources get the latest information from previously created resources
4. **Error Prevention**: Dependencies prevent race conditions and missing resource errors
5. **Scalability**: Easy to add more session hosts or modify configurations

## 🔧 **Troubleshooting**

### **Common Issues & Solutions:**

1. **Scaling Plan Creation Fails**
   - Check if host pool exists and is properly configured
   - Verify role assignment is successful
   - Ensure session hosts are deployed

2. **Dashboard Shows No Data**
   - Verify Log Analytics workspace is created
   - Check diagnostic settings are properly configured
   - Ensure scaling plan is active

3. **Monitoring Resources Fail**
   - Check if Log Analytics workspace exists
   - Verify resource group permissions
   - Ensure all prerequisite resources are created

## 📊 **Resource Creation Timeline**

```
Time 0-2min:   Foundation (RG, Network, AVD Core)
Time 2-8min:   Session Hosts & Extensions
Time 8-9min:   Monitoring Infrastructure
Time 9-10min:  Scaling Plan Prerequisites (Subscription, UUID, Role, Service Principal)
Time 10-11min: Scaling Plan Creation & Host Pool Association
Time 11-12min: Advanced Monitoring & Dashboard
```

This ensures that the scaling plan has all the information it needs about the deployed infrastructure and can properly manage the session hosts. 