// Module for creating an app service plan
// Parameters
@description('App service plan prefix.')
param appServicePlanName string

@description('App service location.')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('App service plan hosting environment profile name (ASEv3 name).')
param hostingEnvironmentProfileName string

@description('App service plan sku.')
param sku string = 'IsolatedV2'

@description('App service plan sku code.')
param skuCode string = 'I1V2'

// Resources
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  sku: {
    tier: sku
    name: skuCode
  }
  properties: {
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', hostingEnvironmentProfileName)
    }
  }
}

output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name
