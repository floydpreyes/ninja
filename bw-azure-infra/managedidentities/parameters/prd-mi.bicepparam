using '../infra-mi.bicep'

// Import common configuration for the production environment
import * as common from '../../prd.common.bicep'

// Core managed identity parameters
param managedIdentityName = 'mi-${common.environment}-${common.region}-${common.projectName}'
param location = common.location

// Tags
param tags = common.tags
