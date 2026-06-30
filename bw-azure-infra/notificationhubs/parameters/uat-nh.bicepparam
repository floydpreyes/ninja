using '../infra-nh.bicep'

// Import common configuration for the UAT environment
import * as common from '../../uat.common.bicep'

// Core Notification Hubs parameters
param namespaceName = 'ntfns-${common.environment}-${common.region}-${common.projectName}'
param notificationHubName = 'ntf-${common.environment}-${common.region}-${common.projectName}'
param location = common.location

// Tags
param tags = common.tags

// SKU - Standard tier for UAT to mirror production
param skuName = 'Standard'

// Public network access (Notification Hubs is a public PaaS service)
param publicNetworkAccess = 'Enabled'

// Managed identity configuration
param enableManagedIdentity = true
param managedIdentityName = 'mi-${common.environment}-${common.region}-${common.projectName}'
param managedIdentityResourceGroup = common.resourceGroup

// Diagnostic settings - send logs to the Sentinel workspace
param enableDiagnosticSettings = true
param logAnalyticsWorkspaceName = common.sentinelWorkspaceName
param logAnalyticsWorkspaceResourceGroup = common.sentinelWorkspaceResourceGroup
param logAnalyticsWorkspaceSubscriptionId = common.hubSubscriptionId
