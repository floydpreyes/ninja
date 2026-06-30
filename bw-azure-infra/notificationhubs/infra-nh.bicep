metadata name = 'WTP Birdwatching Notification Hubs Infrastructure'
metadata description = 'Creates a Notification Hubs namespace and hub for WTP Birdwatching mobile push notifications using Azure Verified Modules'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The name of the Notification Hubs namespace')
param namespaceName string

@description('The name of the notification hub')
param notificationHubName string

@description('The location for the Notification Hubs namespace')
param location string = resourceGroup().location

@description('Tags to apply to the resources')
param tags object = {}

@description('Notification Hubs namespace SKU')
@allowed([
  'Free'
  'Basic'
  'Standard'
])
param skuName string = 'Free'

@description('Enable user-assigned managed identity')
param enableManagedIdentity bool = false

@description('Name of the managed identity to reference')
param managedIdentityName string = ''

@description('Managed identity resource group')
param managedIdentityResourceGroup string = resourceGroup().name

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Enable diagnostic settings')
param enableDiagnosticSettings bool = true

@description('Log Analytics workspace name for diagnostic settings')
param logAnalyticsWorkspaceName string = ''

@description('Log Analytics workspace resource group')
param logAnalyticsWorkspaceResourceGroup string = ''

@description('Log Analytics workspace subscription ID')
param logAnalyticsWorkspaceSubscriptionId string = ''

// ============================================================================
// EXISTING RESOURCES
// ============================================================================

// Reference existing managed identity if enabled
resource existingManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (enableManagedIdentity && !empty(managedIdentityName)) {
  name: managedIdentityName
  scope: resourceGroup(managedIdentityResourceGroup)
}

// Reference existing Log Analytics workspace for diagnostic settings
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = if (enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName)) {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceSubscriptionId, logAnalyticsWorkspaceResourceGroup)
}

// ============================================================================
// RESOURCES
// ============================================================================

// Notification Hubs namespace (no AVM module exists for Notification Hubs)
resource notificationHubNamespace 'Microsoft.NotificationHubs/namespaces@2023-09-01' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    namespaceType: 'NotificationHub'
    publicNetworkAccess: publicNetworkAccess
  }
}

// Notification hub within the namespace
resource notificationHub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2023-09-01' = {
  parent: notificationHubNamespace
  name: notificationHubName
  location: location
  tags: tags
  properties: {}
}

// Diagnostic settings for the namespace
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName)) {
  name: '${namespaceName}-diagnostics'
  scope: notificationHubNamespace
  properties: {
    workspaceId: existingLogAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the Notification Hubs namespace')
output namespaceResourceId string = notificationHubNamespace.id

@description('The name of the Notification Hubs namespace')
output namespaceName string = notificationHubNamespace.name

@description('The resource ID of the notification hub')
output notificationHubResourceId string = notificationHub.id

@description('The name of the notification hub')
output notificationHubName string = notificationHub.name

@description('The location of the Notification Hubs namespace')
output location string = notificationHubNamespace.location

@description('Managed identity resource ID used by the namespace')
output managedIdentityResourceId string = enableManagedIdentity && !empty(managedIdentityName) ? existingManagedIdentity.id : ''

@description('Diagnostic settings enabled status')
output diagnosticSettingsEnabled bool = enableDiagnosticSettings
