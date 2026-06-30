metadata name = 'WTP Birdwatching Key Vault Infrastructure'
metadata description = 'Creates Key Vault for WTP Birdwatching workloads using Azure Verified Modules'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The name of the key vault')
param keyVaultName string

@description('The location for the key vault')
param location string = resourceGroup().location

@description('Tags to apply to the key vault')
param tags object = {}

@description('Key Vault SKU')
@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'

@description('Enable RBAC authorization for data plane operations')
param enableRbacAuthorization bool = true

@description('Enable soft delete functionality')
param enableSoftDelete bool = true

@description('Enable purge protection (irreversible)')
param enablePurgeProtection bool = true

@description('Soft delete retention period in days (7-90)')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Property to specify whether Azure Virtual Machines are permitted to retrieve certificates')
param enabledForDeployment bool = false

@description('Property to specify whether Azure Disk Encryption is permitted to retrieve secrets')
param enabledForDiskEncryption bool = true

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets')
param enabledForTemplateDeployment bool = true

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Default action for network access rules')
@allowed([
  'Allow'
  'Deny'
])
param defaultAction string = 'Deny'

@description('Network bypass setting')
@allowed([
  'AzureServices'
  'None'
])
param bypass string = 'AzureServices'

@description('IP rules for network access')
param ipRules array = []

@description('Virtual network rules')
param virtualNetworkRules array = []

@description('Enable private endpoints')
param enablePrivateEndpoints bool = true

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

@description('Access policies for the key vault (used when RBAC is disabled)')
param accessPolicies array = []

@description('Keys to create in the key vault')
param keys array = []

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

// Network access configuration variables
var ipRulesFormatted = [for rule in ipRules: {
  value: rule
}]

var virtualNetworkRulesFormatted = [for rule in virtualNetworkRules: {
  id: rule
  ignoreMissingVnetServiceEndpoint: false
}]

// Network access configuration
var networkAcls = (publicNetworkAccess == 'Disabled' || defaultAction == 'Deny') ? {
  defaultAction: defaultAction
  bypass: bypass
  ipRules: ipRulesFormatted
  virtualNetworkRules: virtualNetworkRulesFormatted
} : null

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

// Reference existing DNS zone for Key Vault private endpoint
resource existingKeyVaultDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (enablePrivateEndpoints) {
  name: 'privatelink.vaultcore.azure.net'
  scope: resourceGroup('${hubSubscriptionId}','${hubNetworkResourceGroup}')
}

// Key Vault using AVM module
module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  params: {
    name: keyVaultName
    location: location
    tags: tags

    // Key Vault configuration
    sku: sku

    // Security configuration
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    enablePurgeProtection: enablePurgeProtection
    softDeleteRetentionInDays: softDeleteRetentionInDays

    // Feature enablement
    enableVaultForDeployment: enabledForDeployment
    enableVaultForDiskEncryption: enabledForDiskEncryption
    enableVaultForTemplateDeployment: enabledForTemplateDeployment

    // Network access configuration
    publicNetworkAccess: publicNetworkAccess
    networkAcls: networkAcls

    // Access policies (only used when RBAC is disabled)
    accessPolicies: enableRbacAuthorization ? [] : accessPolicies

    // Private endpoints configuration
    privateEndpoints: enablePrivateEndpoints ? [
      {
        name: privateEndpointNamePrefix
        service: 'vault'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: existingKeyVaultDnsZone.id
            }
          ]
        }
        tags: tags
      }
    ] : []

    // Secrets configuration
    secrets: []

    // Keys configuration
    keys: [for key in keys: {
      name: key.name
      kty: key.?keyType ?? 'RSA'
      keySize: key.?keySize ?? 2048
      keyOps: key.?keyOps ?? [
        'encrypt'
        'decrypt'
        'sign'
        'verify'
        'wrapKey'
        'unwrapKey'
      ]
      attributes: {
        enabled: key.?enabled ?? true
        exp: key.?expirationDate
        nbf: key.?notBeforeDate
      }
      rotationPolicy: {
        attributes: {
          expiryTime: 'P100D'
        }
        lifetimeActions: [
          {
            action: {
              type: 'rotate'
            }
            trigger: {
              timeAfterCreate: 'P90D'
              timeBeforeExpiry: 'P91D'
            }
          }
        ]
      }
    }]

    // Diagnostic settings configuration
    diagnosticSettings: enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName) ? [
      {
        name: '${keyVaultName}-diagnostics'
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

    // Enable telemetry for AVM module
    enableTelemetry: true
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the key vault')
output keyVaultResourceId string = keyVault.outputs.resourceId

@description('The name of the key vault')
output keyVaultName string = keyVault.outputs.name

@description('The URI of the key vault')
output keyVaultUri string = keyVault.outputs.uri

@description('Private endpoints created for the key vault')
output privateEndpoints array = enablePrivateEndpoints ? keyVault.outputs.privateEndpoints : []

@description('Managed identity resource ID used by the key vault')
output managedIdentityResourceId string = enableManagedIdentity && !empty(managedIdentityName) ? existingManagedIdentity.id : ''

@description('Managed identity name used by the key vault')
output managedIdentityName string = enableManagedIdentity && !empty(managedIdentityName) ? managedIdentityName : ''

@description('The location of the key vault')
output location string = keyVault.outputs.location

@description('Diagnostic settings enabled status')
output diagnosticSettingsEnabled bool = enableDiagnosticSettings

@description('Log Analytics workspace used for diagnostics')
output diagnosticsWorkspace string = enableDiagnosticSettings && !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : ''
