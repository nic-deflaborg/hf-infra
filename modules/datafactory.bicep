// Module for creating a data factory instance
// Parameters
@description('Name of data factory workspace.')
param dataFactoryName string

@description('Data Factory resource group location')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('Data Factory identity type.')
@allowed([
  'SystemAssigned'
  'SystemAssigned,UserAssigned'
  'UserAssigned'
])
param identity string

// Resources
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' =  {
  name: dataFactoryName
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  identity: {
    type: identity
  }
  properties: {}
}

output dataFactoryId string = dataFactory.id
output dataFactoryName string = dataFactory.name
