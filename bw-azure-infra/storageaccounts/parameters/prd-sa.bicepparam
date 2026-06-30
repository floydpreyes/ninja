using '../infra-sa.bicep'

// Import common configuration for the production environment
import * as common from '../../prd.common.bicep'

// Core storage account parameters
param storageAccountName = 'st${common.environment}${common.region}${common.projectName}'
param environment = common.environment
param location = common.location
param hubSubscriptionId = common.hubSubscriptionId
param hubNetworkResourceGroup = common.hubNetworkResourceGroup

// Tags
param tags = common.tags

// Storage configuration
param storageAccountKind = 'StorageV2'
param storageAccountSku = 'Standard_GRS'

// Security configuration
param supportsHttpsTrafficOnly = true
param minimumTlsVersion = 'TLS1_2'
param allowBlobPublicAccess = false
param enableAutomaticSnapshots = false
param enableHierarchicalNamespace = false

// Network configuration
param defaultAction = 'Deny'

// Container and file share configuration
param containerNames = []
param fileShareNames = []

// Private endpoint configuration
param enablePrivateEndpoints = true
param privateEndpointSubnetId = '/subscriptions/${common.subscriptionId}/resourceGroups/${common.networkResourceGroup}/providers/Microsoft.Network/virtualNetworks/${common.vnetName}/subnets/${common.peSubnet}'
param privateEndpointNamePrefix = 'pep-${common.environment}-${common.region}-${common.projectName}-st'

// Managed identity configuration
param enableManagedIdentity = true
param managedIdentityName = 'mi-${common.environment}-${common.region}-${common.projectName}'

// Customer-managed encryption configuration
param enableCustomerManagedEncryption = true
param keyVaultResourceId = '/subscriptions/${common.subscriptionId}/resourceGroups/${common.resourceGroup}/providers/Microsoft.KeyVault/vaults/kv-${common.environment}-${common.region}-${common.projectName}'
param keyVaultKeyName = 'storage-encryption-key'
param encryptionUserAssignedIdentityResourceId = '/subscriptions/${common.subscriptionId}/resourceGroups/${common.resourceGroup}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-${common.environment}-${common.region}-${common.projectName}'

// Diagnostic settings - send logs to the Sentinel workspace
param enableDiagnosticSettings = true
param logAnalyticsWorkspaceName = common.sentinelWorkspaceName
param logAnalyticsWorkspaceResourceGroup = common.sentinelWorkspaceResourceGroup
param logAnalyticsWorkspaceSubscriptionId = common.hubSubscriptionId
