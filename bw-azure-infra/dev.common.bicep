@description('The subscription that the Azure resources will be deployed to')
@export()
var subscriptionId = 'REPLACE-WITH-DEV-SUBSCRIPTION-ID'

@export()
var hubSubscriptionId = '63656dd5-d2aa-4c65-9b6b-5329dd6620af'

@export()
var projectName = 'bw'

@export()
var environment = 'devtest'

@export()
var region = 'ase'

@export()
var location = 'australiasoutheast'

@export()
var extension = ''

@export()
var shortExtension = ''

@export()
var tags = {
  ApplicationName: 'WTP Birdwatching'
  BusinessDomain: 'Customer_Corporate'
  CostCentre: 'REPLACE-WITH-COST-CENTRE'
  Environment: 'Development'
  Project: 'WTP Birdwatching'
  DeploymentType: 'Bicep'
  OpsTeam: 'CloudOps'
  Owner: 'WTP Birdwatching'
  SLA: '8*5'
}

/* Networking */
@export()
var networkResourceGroup = 'rg-dev_test-network-${region}'

@export()
var hubNetworkResourceGroup = 'rg-hub-ase'

@export()
var vnetName = 'vnet-dev-test-${region}'

@description('The subnet for app service / app service plan VNet integration')
@export()
var appEnvSubnet = 'sn-dev-test-aisappenv-${region}'

@description('The subnet for private endpoints')
@export()
var peSubnet = 'sn-dev-test-aispe-${region}'

@export()
var resourceGroup = 'rg-${environment}-${region}-${projectName}'

/* Monitoring */
@export()
var appInsightsName = 'appi-${environment}-${region}-${projectName}'

/* App service plan */
@export()
var appServicePlanName = 'asp-${environment}-${region}-${projectName}'

/* Key vault */
@export()
var keyVaultName = 'kv-${environment}-${region}-${projectName}${extension}'

@description('The keyvault url for this environment')
@export()
var keyvaultSecretsUrl = 'https://${az.environment().suffixes.keyvaultDns}/secrets'

/* Diagnostics - Sentinel hub workspace (devtest uses the -test workspace) */
@export()
var sentinelWorkspaceName = 'la-hub-ae-sentinel-test'

@export()
var sentinelWorkspaceResourceGroup = 'rg-hub-ae-sentinel'

/* Authentication */
@export()
var appRegistrationClientId = 'REPLACE-WITH-APP-REGISTRATION-CLIENT-ID'

@export()
var tenantId = 'fe26127b-78ee-42c7-803e-4d67c0488cf9'
