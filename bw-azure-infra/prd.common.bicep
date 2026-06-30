@description('The subscription that the Azure resources will be deployed to')
@export()
var subscriptionId = 'REPLACE-WITH-PRD-SUBSCRIPTION-ID'

@export()
var hubSubscriptionId = '63656dd5-d2aa-4c65-9b6b-5329dd6620af'

@export()
var projectName = 'bw'

@export()
var environment = 'prd'

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
  Environment: 'Production'
  Project: 'WTP Birdwatching'
  DeploymentType: 'Bicep'
  OpsTeam: 'CloudOps'
  Owner: 'WTP Birdwatching'
  SLA: '24*7'
  CriticalityLevel: 'High'
  DataClassification: 'Confidential'
  BackupRequired: 'Yes'
  MonitoringRequired: 'Yes'
}

/* Networking */
@export()
var networkResourceGroup = 'rg-PRD-network-${region}'

@export()
var hubNetworkResourceGroup = 'rg-hub-${region}'

@export()
var vnetName = 'vnet-${environment}-${region}'

@description('The subnet for app service / app service plan VNet integration')
@export()
var appEnvSubnet = 'sn-${environment}-ais-${region}-03'

@description('The subnet for private endpoints')
@export()
var peSubnet = 'sn-${environment}-ais-${region}-04'

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
var keyvaultSecretsUrl = 'https://${keyVaultName}.${az.environment().suffixes.keyvaultDns}/secrets'

/* Diagnostics - Sentinel hub workspace (prod) */
@export()
var sentinelWorkspaceName = 'la-hub-ae-sentinel'

@export()
var sentinelWorkspaceResourceGroup = 'rg-hub-ae-sentinel'

/* Alerts */
@export()
var actionGroupName = 'ag-${environment}-${region}-${projectName}'

@export()
var alertsEnabled = true

/* Authentication */
@export()
var appRegistrationClientId = 'REPLACE-WITH-APP-REGISTRATION-CLIENT-ID'

@export()
var tenantId = 'fe26127b-78ee-42c7-803e-4d67c0488cf9'
