// Module for creating an app service with an associated application insights instance and optional keyvault access policy
// Parameters
@description('App service prefix.')
param appName string

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

@description('Enable Always-on of App service.')
param alwaysOn bool = true

@description('Enable php of App service.')
param phpVersion string = 'OFF'

@description('.NET Framework version of App service.')
param netFrameworkVersion string = 'v5.0'

@description('App service plan Id')
param appServicePlanId string

@description('Resource Id of the log analytics workspace')
param logAnalyticsId string

@description('Type of app service, eg web, function')
param kind string

@description('Optional name of the KeyVault')
param keyVaultResourceName string = ''

@description('Assigned secret permissions for Principal Id')
param secretPermissions string = ''

@description('Policy action.')
@allowed([
  'add'
  'remove'
  'replace'
])
param policyAction string = 'add'

@description('Optional add permissions to keyvault access policy')
param keyVaultAccessPolicy bool = false

@description('Enable function app logging')
param functionAppLogs bool = true

// Resources
module appInsights './appinsights.bicep' = {
  name: 'ai-${appName}'
  params: {
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    applicationInsightsName: 'ai-${appName}'
    location: location
    workspaceResourceId: logAnalyticsId
  }
}

resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: appName
  kind: kind
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      phpVersion: phpVersion
      netFrameworkVersion: netFrameworkVersion
      alwaysOn: alwaysOn
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.outputs.instrumentationKey
        }
      ]
      ftpsState: 'Disabled'
      http20Enabled: true
    }
    serverFarmId: appServicePlanId
    clientAffinityEnabled: true
    httpsOnly: true
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', hostingEnvironmentProfileName)
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = if (keyVaultAccessPolicy) {
  name: keyVaultResourceName
  resource keyVaultPolicies 'accessPolicies' = {
    name: policyAction
    properties: {    
      accessPolicies: [
        {
          objectId: appService.identity.principalId
          permissions: {
            secrets: [
              secretPermissions
            ]
          }
          tenantId: subscription().tenantId
        }
      ]
    }
  }  
}

resource appServiceDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'appServiceLogAnalytics'
  scope: appService
  properties: {
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: functionAppLogs
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

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServicePrincipalId string = appService.identity.principalId
output instrumentationKey string = appInsights.outputs.instrumentationKey
