using '../infra-mi.bicep'

// Import common configuration for the uat environment
import * as common from '../../uat.common.bicep'

// Core managed identity parameters
param managedIdentityName = 'mi-${common.environment}-${common.region}-${common.projectName}'
param location = common.location

// Tags
param tags = common.tags
