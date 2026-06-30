using '../infra-nh.bicep'

// Import common configuration for the dev environment
import * as common from '../../dev.common.bicep'

// Core Notification Hubs parameters
param namespaceName = 'ntfns-${common.environment}-${common.region}-${common.projectName}'
param notificationHubName = 'ntf-${common.environment}-${common.region}-${common.projectName}'
param location = common.location

// Tags
param tags = common.tags

// SKU - Free tier for dev
param skuName = 'Free'

// Public network access (Notification Hubs is a public PaaS service)
param publicNetworkAccess = 'Enabled'

// Managed identity configuration
param enableManagedIdentity = true
param managedIdentityName = 'mi-${common.environment}-${common.region}-${common.projectName}'
param managedIdentityResourceGroup = common.resourceGroup

// Diagnostic settings - send logs to the test Sentinel workspace
param enableDiagnosticSettings = true
param logAnalyticsWorkspaceName = common.sentinelWorkspaceName
param logAnalyticsWorkspaceResourceGroup = common.sentinelWorkspaceResourceGroup
param logAnalyticsWorkspaceSubscriptionId = common.hubSubscriptionId
