// Module for creating a service bus namespace and queues
// Parameters
@description('Service bus namespace name')
param serviceBusNamespaceName string

@description('Service bus resource group Location')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('sku name')
param skuName string = 'Basic'

@description('names of the queues to be created')
param queueNames array

@description('Resource Id of the log analytics workspace')
param logAnalyticsId string

@description('enable allLogs diagnostics')
param allLogs bool = true

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  sku: {
    name: skuName
  }
}

resource queues 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = [for queueName in queueNames: {
  parent: serviceBusNamespace
  name: queueName
}]

resource serviceBusDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'serviceBusLogAnalytics'
  scope: serviceBusNamespace
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: allLogs
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsId
  }
}
