// Module for creation of log analytics workspace
// Parameters
@description('Name of log analytics workspace')
param logAnalyticsNamespaceName string

@description('Log analytics workspace location.')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('The name of the sku.')
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param skuName string = 'PerNode'

// Resources
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsNamespaceName
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  properties: {
    sku: {
      name: skuName
    }
  }
}

output logAnalyticsId string = logAnalyticsWorkspace.id
