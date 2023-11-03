// Module for creating application insights
// Parameters
@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('Application Insights resource name')
param applicationInsightsName string

param kind string = 'web'

@description('Type of application')
@allowed([
  'other'
  'web'
])
param applicationType string = 'web'

@description('resource id of log analytics workspace')
param workspaceResourceId string

// Resources
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  kind: kind
  properties: {
    Application_Type: applicationType
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: workspaceResourceId
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

output instrumentationKey string = applicationInsights.properties.InstrumentationKey
