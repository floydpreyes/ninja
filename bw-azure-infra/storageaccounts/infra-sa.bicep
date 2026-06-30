metadata name = 'WTP Birdwatching Storage Account Infrastructure'
metadata description = 'Creates storage accounts for WTP Birdwatching workloads using Azure Verified Modules'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The name of the storage account')
param storageAccountName string

@description('The environment name (dev, test, uat, prd)')
param environment string

@description('The location for the storage account')
param location string = resourceGroup().location

@description('Tags to apply to the storage account')
param tags object = {}

@description('Storage account kind')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param storageAccountKind string = 'StorageV2'

@description('Storage account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
])
param storageAccountSku string = 'Standard_LRS'

@description('Enable HTTPS traffic only')
param supportsHttpsTrafficOnly bool = true

@description('Minimum TLS version')
@allowed([
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Enable blob public access')
param allowBlobPublicAccess bool = false

@description('Enable shared key access')
param allowSharedKeyAccess bool = true

@description('Default action for network access')
@allowed([
  'Allow'
  'Deny'
])
param defaultAction string = 'Allow'

@description('Container names to create')
param containerNames array = []

@description('File share names to create')
param fileShareNames array = []

@description('Enable private endpoints')
param enablePrivateEndpoints bool = false

param hubSubscriptionId string = ''

param hubNetworkResourceGroup string = ''

@description('Subnet resource ID for private endpoints')
param privateEndpointSubnetId string = ''

@description('Private endpoint name prefix')
param privateEndpointNamePrefix string = ''

@description('Enable user-assigned managed identity')
param enableManagedIdentity bool = false

@description('Name of the managed identity to reference')
param managedIdentityName string = ''

@description('Enable blob soft delete')
param enableBlobSoftDelete bool = true

@description('Number of days to retain deleted blobs')
@minValue(1)
@maxValue(365)
param blobSoftDeleteRetentionDays int = 7

@description('Enable blob versioning')
param enableBlobVersioning bool = false

@description('Enable blob change feed')
param enableBlobChangeFeed bool = false

@description('Enable automatic blob snapshots before overwrite (requires versioning)')
param enableAutomaticSnapshots bool = false

@description('Enable hierarchical namespace (for Data Lake Storage Gen2)')
param enableHierarchicalNamespace bool = false

@description('Enable customer-managed encryption using Key Vault key')
param enableCustomerManagedEncryption bool = false

@description('Key Vault resource ID for customer-managed encryption')
param keyVaultResourceId string = ''

@description('Key name in Key Vault for customer-managed encryption')
param keyVaultKeyName string = 'storage-encryption-key'

@description('User-assigned managed identity resource ID for Key Vault access')
param encryptionUserAssignedIdentityResourceId string = ''

@description('Enable diagnostic settings')
param enableDiagnosticSettings bool = true

@description('Log Analytics workspace name for diagnostic settings')
param logAnalyticsWorkspaceName string = ''

@description('Log Analytics workspace resource group')
param logAnalyticsWorkspaceResourceGroup string = ''

@description('Log Analytics workspace subscription ID')
param logAnalyticsWorkspaceSubscriptionId string = ''

// ============================================================================
// VARIABLES
// ============================================================================

// Network access configuration for production environments
var networkAcls = environment == 'prd' ? {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
} : {
  defaultAction: defaultAction
}

// ============================================================================
// RESOURCES
// ============================================================================

// Reference existing managed identity if enabled
resource existingManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (enableManagedIdentity && !empty(managedIdentityName)) {
  name: managedIdentityName
}

// Reference existing Log Analytics workspace for diagnostic settings
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = if (enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName)) {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceSubscriptionId, logAnalyticsWorkspaceResourceGroup)
}

resource existingBlobDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.blob.${az.environment().suffixes.storage}'
  scope: resourceGroup('${hubSubscriptionId}','${hubNetworkResourceGroup}')
}

resource existingFileDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.file.${az.environment().suffixes.storage}'
  scope: resourceGroup('${hubSubscriptionId}','${hubNetworkResourceGroup}')
}

resource existingTableDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.table.${az.environment().suffixes.storage}'
  scope: resourceGroup('${hubSubscriptionId}','${hubNetworkResourceGroup}')
}

resource existingQueueDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.queue.${az.environment().suffixes.storage}'
  scope: resourceGroup('${hubSubscriptionId}','${hubNetworkResourceGroup}')
}

resource existingDfsDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.dfs.${az.environment().suffixes.storage}'
  scope: resourceGroup('${hubSubscriptionId}','${hubNetworkResourceGroup}')
}

// Storage account using AVM module
module storageAccount 'br/public:avm/res/storage/storage-account:0.27.0' = {
  params: {
    name: storageAccountName
    location: location
    tags: tags

    // Storage configuration
    kind: storageAccountKind
    skuName: storageAccountSku

    // Security configuration
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: true
    enableHierarchicalNamespace: enableHierarchicalNamespace

    // Network access configuration
    networkAcls: networkAcls

    // Customer-managed encryption configuration
    customerManagedKey: enableCustomerManagedEncryption ? {
      keyName: keyVaultKeyName
      keyVaultResourceId: keyVaultResourceId
      userAssignedIdentityResourceId: encryptionUserAssignedIdentityResourceId
    } : null

    // Managed identity configuration
    managedIdentities: enableManagedIdentity && !empty(managedIdentityName) ? {
      userAssignedResourceIds: [
        existingManagedIdentity.id
      ]
    } : null

    // Role assignments handled separately
    roleAssignments: []

    // Blob services configuration with soft delete and versioning
    blobServices: {
      automaticSnapshotPolicyEnabled: enableAutomaticSnapshots
      containerDeleteRetentionPolicyDays: 10
      containerDeleteRetentionPolicyEnabled: true
      lastAccessTimeTrackingPolicyEnabled: true
      deleteRetentionPolicyEnabled: enableBlobSoftDelete
      deleteRetentionPolicyDays: blobSoftDeleteRetentionDays
      isVersioningEnabled: enableBlobVersioning
      changeFeedEnabled: enableBlobChangeFeed
      containers: [for containerName in containerNames: {
        name: containerName
        publicAccess: 'None'
      }]
      diagnosticSettings: enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName) ? [
        {
          name: '${storageAccountName}-blob-diagnostics'
          workspaceResourceId: existingLogAnalyticsWorkspace.id
          logCategoriesAndGroups: [
            {
              category: 'StorageRead'
              enabled: true
            }
            {
              category: 'StorageWrite'
              enabled: true
            }
            {
              category: 'StorageDelete'
              enabled: true
            }
          ]
          metricCategories: [
            {
              category: 'Transaction'
              enabled: true
            }
            {
              category: 'Capacity'
              enabled: true
            }
          ]
        }
      ] : []
    }

    // File services configuration
    fileServices: {
      shares: [for shareName in fileShareNames: {
        name: shareName
      }]
      diagnosticSettings: enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName) ? [
        {
          name: '${storageAccountName}-file-diagnostics'
          workspaceResourceId: existingLogAnalyticsWorkspace.id
          logCategoriesAndGroups: [
            {
              category: 'StorageRead'
              enabled: true
            }
            {
              category: 'StorageWrite'
              enabled: true
            }
            {
              category: 'StorageDelete'
              enabled: true
            }
          ]
          metricCategories: [
            {
              category: 'Transaction'
              enabled: true
            }
            {
              category: 'Capacity'
              enabled: true
            }
          ]
        }
      ] : []
    }

    // Queue services configuration
    queueServices: {
      diagnosticSettings: enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName) ? [
        {
          name: '${storageAccountName}-queue-diagnostics'
          workspaceResourceId: existingLogAnalyticsWorkspace.id
          logCategoriesAndGroups: [
            {
              category: 'StorageRead'
              enabled: true
            }
            {
              category: 'StorageWrite'
              enabled: true
            }
            {
              category: 'StorageDelete'
              enabled: true
            }
          ]
          metricCategories: [
            {
              category: 'Transaction'
              enabled: true
            }
            {
              category: 'Capacity'
              enabled: true
            }
          ]
        }
      ] : []
    }

    // Table services configuration
    tableServices: {
      diagnosticSettings: enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName) ? [
        {
          name: '${storageAccountName}-table-diagnostics'
          workspaceResourceId: existingLogAnalyticsWorkspace.id
          logCategoriesAndGroups: [
            {
              category: 'StorageRead'
              enabled: true
            }
            {
              category: 'StorageWrite'
              enabled: true
            }
            {
              category: 'StorageDelete'
              enabled: true
            }
          ]
          metricCategories: [
            {
              category: 'Transaction'
              enabled: true
            }
            {
              category: 'Capacity'
              enabled: true
            }
          ]
        }
      ] : []
    }

    // Enable telemetry for AVM module
    enableTelemetry: true

    // Account-level diagnostic settings
    diagnosticSettings: enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName) ? [
      {
        name: '${storageAccountName}-diagnostics'
        workspaceResourceId: existingLogAnalyticsWorkspace.id
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ] : []

    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'

    // Private endpoints configuration
    privateEndpoints: enablePrivateEndpoints ? [
      {
        name: '${privateEndpointNamePrefix}b'  // blob
        service: 'blob'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: existingBlobDnsZone.id
            }
          ]
        }
        tags: tags
      }
      {
        name: '${privateEndpointNamePrefix}f'  // file
        service: 'file'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: existingFileDnsZone.id
            }
          ]
        }
        tags: tags
      }
      {
        name: '${privateEndpointNamePrefix}q'  // queue
        service: 'queue'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: existingQueueDnsZone.id
            }
          ]
        }
        tags: tags
      }
      {
        name: '${privateEndpointNamePrefix}t'  // table
        service: 'table'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: existingTableDnsZone.id
            }
          ]
        }
        tags: tags
      }
      {
        name: '${privateEndpointNamePrefix}d'  // dfs
        service: 'dfs'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: existingDfsDnsZone.id
            }
          ]
        }
        tags: tags
      }
    ] : []
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the storage account')
output storageAccountResourceId string = storageAccount.outputs.resourceId

@description('The name of the storage account')
output storageAccountName string = storageAccount.outputs.name

@description('Private endpoints created for the storage account')
output privateEndpoints array = enablePrivateEndpoints ? storageAccount.outputs.privateEndpoints : []

@description('Managed identity resource ID used by the storage account')
output managedIdentityResourceId string = enableManagedIdentity && !empty(managedIdentityName) ? existingManagedIdentity.id : ''

@description('Managed identity name used by the storage account')
output managedIdentityName string = enableManagedIdentity && !empty(managedIdentityName) ? managedIdentityName : ''

@description('Customer-managed encryption enabled status')
output customerManagedEncryptionEnabled bool = enableCustomerManagedEncryption

@description('Key Vault resource ID used for encryption')
output encryptionKeyVaultResourceId string = enableCustomerManagedEncryption ? keyVaultResourceId : ''

@description('Encryption key name used')
output encryptionKeyName string = enableCustomerManagedEncryption ? keyVaultKeyName : ''

@description('Diagnostic settings enabled status')
output diagnosticSettingsEnabled bool = enableDiagnosticSettings
