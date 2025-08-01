{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "# Azure Virtual Desktop Insights\n\n**Environment:** ${environment}\n**Deployment Type:** ${deployment_type}\n**Resource Group:** ${resource_group}\n\nThis dashboard provides comprehensive monitoring for your AVD deployment including session metrics, performance data, and cost insights.",
                  "title": "AVD Overview",
                  "subtitle": "Real-time monitoring and insights"
                }
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 6,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## Quick Actions\n\n- [AVD Host Pool](https://portal.azure.com/#@/resource${host_pool_id})\n- [Log Analytics](https://portal.azure.com/#@/resource${workspace_id})\n- [Resource Group](https://portal.azure.com/#@/resource/subscriptions/{{subscription().subscriptionId}}/resourceGroups/${resource_group})\n\n## Refresh Interval\n\n${refresh_interval} minutes",
                  "title": "Navigation",
                  "subtitle": "Quick access to resources"
                }
              }
            }
          }
        },
        "2": {
          "position": {
            "x": 0,
            "y": 4,
            "colSpan": 3,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## Active Sessions\n\n**Current:** {{#activityLogAlertRule}}Active Sessions{{/activityLogAlertRule}}\n**Peak Today:** {{#activityLogAlertRule}}Peak Sessions{{/activityLogAlertRule}}\n**Total Users:** {{#activityLogAlertRule}}Total Users{{/activityLogAlertRule}}",
                  "title": "Session Metrics",
                  "subtitle": "Real-time session data"
                }
              }
            }
          }
        },
        "3": {
          "position": {
            "x": 3,
            "y": 4,
            "colSpan": 3,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## Performance\n\n**CPU Avg:** {{#activityLogAlertRule}}CPU Usage{{/activityLogAlertRule}}\n**Memory Avg:** {{#activityLogAlertRule}}Memory Usage{{/activityLogAlertRule}}\n**Disk Avg:** {{#activityLogAlertRule}}Disk Usage{{/activityLogAlertRule}}",
                  "title": "Performance Metrics",
                  "subtitle": "Resource utilization"
                }
              }
            }
          }
        },
        "4": {
          "position": {
            "x": 6,
            "y": 4,
            "colSpan": 3,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## Cost Insights\n\n**Daily Cost:** {{#activityLogAlertRule}}Daily Cost{{/activityLogAlertRule}}\n**Monthly Cost:** {{#activityLogAlertRule}}Monthly Cost{{/activityLogAlertRule}}\n**Cost per User:** {{#activityLogAlertRule}}Cost per User{{/activityLogAlertRule}}",
                  "title": "Cost Analysis",
                  "subtitle": "Spending insights"
                }
              }
            }
          }
        },
        "5": {
          "position": {
            "x": 9,
            "y": 4,
            "colSpan": 3,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## Health Status\n\n**Host Pool:** {{#activityLogAlertRule}}Host Pool Status{{/activityLogAlertRule}}\n**Session Hosts:** {{#activityLogAlertRule}}Session Host Status{{/activityLogAlertRule}}\n**Applications:** {{#activityLogAlertRule}}App Status{{/activityLogAlertRule}}",
                  "title": "Health Overview",
                  "subtitle": "System status"
                }
              }
            }
          }
        },
        "6": {
          "position": {
            "x": 0,
            "y": 7,
            "colSpan": 12,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## Recent Alerts and Events\n\n{{#activityLogAlertRule}}Recent Events{{/activityLogAlertRule}}\n\n### Scaling Plan Status\n- **Last Scale Up:** {{#activityLogAlertRule}}Last Scale Up{{/activityLogAlertRule}}\n- **Last Scale Down:** {{#activityLogAlertRule}}Last Scale Down{{/activityLogAlertRule}}\n- **Scaling Plan Status:** {{#activityLogAlertRule}}Scaling Status{{/activityLogAlertRule}}\n\n### Connection Analytics\n- **Successful Connections:** {{#activityLogAlertRule}}Successful Connections{{/activityLogAlertRule}}\n- **Failed Connections:** {{#activityLogAlertRule}}Failed Connections{{/activityLogAlertRule}}\n- **Average Connection Time:** {{#activityLogAlertRule}}Connection Time{{/activityLogAlertRule}}",
                  "title": "Events & Alerts",
                  "subtitle": "Recent activity and notifications"
                }
              }
            }
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      },
      "filterLocale": {
        "value": "en-us"
      },
      "filters": {
        "value": {
          "MsPortalFx_TimeRange": {
            "model": {
              "format": "utc",
              "value": {
                "relative": {
                  "duration": 24,
                  "timeUnit": 1
                }
              }
            },
            "displayCache": {
              "name": "Past 24 hours",
              "value": "Past 24 hours"
            },
            "filteredPartIds": {
              "0": "MarkdownPart"
            }
          }
        }
      }
    }
  },
  "name": "AVD Insights Dashboard",
  "type": "Microsoft.Portal/dashboards",
  "location": "eastus",
  "tags": {
    "environment": "${environment}",
    "deployment_type": "${deployment_type}",
    "created_by": "terraform"
  }
} 