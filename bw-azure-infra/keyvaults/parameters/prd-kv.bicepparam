using '../infra-kv.bicep'

// Import common configuration for the production environment
import * as common from '../../prd.common.bicep'

// Core Key Vault parameters
param keyVaultName = 'kv-${common.environment}-${common.region}-${common.projectName}'
param location = common.location
param hubSubscriptionId = common.hubSubscriptionId
param hubNetworkResourceGroup = common.hubNetworkResourceGroup

// Tags
param tags = common.tags

// Key Vault configuration
param sku = 'standard'

// Security configuration
param enableRbacAuthorization = true
param enableSoftDelete = true
param enablePurgeProtection = true  // Required for customer-managed encryption
param softDeleteRetentionInDays = 90

// Feature enablement
param enabledForDeployment = false
param enabledForDiskEncryption = true
param enabledForTemplateDeployment = true

// Network configuration - restrictive, private access only
param publicNetworkAccess = 'Disabled'
param defaultAction = 'Deny'
param bypass = 'AzureServices'
param ipRules = []
param virtualNetworkRules = []

// Private endpoint configuration
param enablePrivateEndpoints = true
param privateEndpointSubnetId = '/subscriptions/${common.subscriptionId}/resourceGroups/${common.networkResourceGroup}/providers/Microsoft.Network/virtualNetworks/${common.vnetName}/subnets/${common.peSubnet}'
param privateEndpointNamePrefix = 'pep-${common.environment}-${common.region}-${common.projectName}-kv'

// Managed identity configuration
param enableManagedIdentity = false
param managedIdentityName = ''

// Keys for customer-managed storage encryption
param keys = [
  {
    name: 'storage-encryption-key'
    keyType: 'RSA'
    keySize: 2048
    keyOps: [
      'encrypt'
      'decrypt'
      'wrapKey'
      'unwrapKey'
    ]
    attributes: {
      enabled: true
      exportable: false
    }
  }
]

// Access policies - RBAC is enabled so these are unused
param accessPolicies = []

// Diagnostic settings - send logs to the Sentinel workspace
param enableDiagnosticSettings = true
param logAnalyticsWorkspaceName = common.sentinelWorkspaceName
param logAnalyticsWorkspaceResourceGroup = common.sentinelWorkspaceResourceGroup
param logAnalyticsWorkspaceSubscriptionId = common.hubSubscriptionId
