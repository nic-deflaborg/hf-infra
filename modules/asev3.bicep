// Module for creating an app service environment
// Parameters
@description('App service prefix.')
param asev3Name string

@description('App service location.')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('Required. Dedicated host count of ASEv3.')
param dedicatedHostCount int = 0

@description('Required. Zone redundant of ASEv3.')
param zoneRedundant bool = false

@description('Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment.')
@allowed([
  'None'
  'Publishing'
  'Web'
])
param internalLoadBalancingMode string = 'None'

@description('Reference to the vnet resource ID for the App Service Environment')
param vnetId string

@description('reference to subnet for the App Service Environment')
param subnetRef string


//Resources
resource asev3 'Microsoft.Web/hostingEnvironments@2021-03-01' = {
  name: asev3Name
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  kind: 'ASEV3'
  properties: {
    dedicatedHostCount: dedicatedHostCount
    zoneRedundant: zoneRedundant
    internalLoadBalancingMode: internalLoadBalancingMode
    virtualNetwork: {
      id: vnetId                                                                       
      subnet: subnetRef
    }
  }
}

output asev3Id string = asev3.id
output asev3Name string = asev3.name
