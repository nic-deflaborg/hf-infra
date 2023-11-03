// Module for creating SQL server and database
// Parameters
@description('Name of SQL server')
param servername string

@description('Name of SQL database')
param dbname string

@description('SQL resource group Location')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('Minimal TLS version.')
param minTlsVersion string = '1.2'

@description('Whether or not public endpoint access is allowed for this server.')
param publicNetworkAccess string = 'disabled'

@description('Resource SKU.')
param sku string

@description('Specifies the state of the transparent data encryption.')
param transparentDataEncryption string = 'Enabled'

@description('AD login name')
param aadLoginName string

@description('AD login SID')
param aadLoginSid string

@description('Resource Id of the log analytics workspace')
param logAnalyticsId string

param subnetRef string

//Variables
//var sqlAdminlogin = 'user${uniqueString(resourceGroup().id)}' // Using AAD auth, so creating random user
//var sqlAdminPassword = 'p@!!${uniqueString(resourceGroup().id)}' // Using AAD auth, so creating random password

// Resources
resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' = {
  location: location
  name: servername
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administrators: {
      principalType: 'Group'
      administratorType: 'ActiveDirectory'
      login: aadLoginName
      sid: aadLoginSid
      tenantId: subscription().tenantId
    }
    administratorLogin: 'admin'
    administratorLoginPassword: 'P@ssw0rd123'
    minimalTlsVersion: minTlsVersion
    publicNetworkAccess: publicNetworkAccess
  }
  resource sqlServerNetwork 'virtualNetworkRules@2021-08-01-preview' = {
    name: 'ase-vnet'
    properties: {
      ignoreMissingVnetServiceEndpoint: false
      virtualNetworkSubnetId: subnetRef
    }
  }
  resource sqlServerAuditing 'auditingSettings@2021-11-01-preview' = {
    name: 'default'
    properties: {
      isAzureMonitorTargetEnabled: true
      state: 'Enabled'
    }
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name:  dbname
  location: location
  sku: {
    name: sku
  }
  resource tde 'transparentDataEncryption' = {
    name: 'current' 
    properties: {
      state: transparentDataEncryption
    }
  }
}

resource serviceBusDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'sqlLogAnalytics'
  scope: sqlDatabase
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsId
  }
}

output sqlServerPrincipalId string = sqlServer.identity.principalId
output sqlServerName string = sqlServer.name
output sqlServerDatabaseName string = sqlDatabase.name

