metadata name = 'WTP Birdwatching Managed Identity Infrastructure'
metadata description = 'Creates user-assigned managed identities for WTP Birdwatching workloads using Azure Verified Modules'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The name of the managed identity')
param managedIdentityName string

@description('The location for the managed identity')
param location string = resourceGroup().location

@description('Tags to apply to the managed identity')
param tags object = {}

// ============================================================================
// RESOURCES
// ============================================================================

// User-assigned managed identity using AVM module
module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  params: {
    name: managedIdentityName
    location: location
    tags: tags

    // Enable telemetry for AVM module
    enableTelemetry: true
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the managed identity')
output managedIdentityResourceId string = managedIdentity.outputs.resourceId

@description('The principal ID of the managed identity')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('The client ID of the managed identity')
output managedIdentityClientId string = managedIdentity.outputs.clientId

@description('The name of the managed identity')
output managedIdentityName string = managedIdentity.outputs.name
