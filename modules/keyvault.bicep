// Module for creating a key vault instance
// Parameters
@description('Name of key vault.')
param keyVaultResourceName string

@description('Key vault location.')
param location string = resourceGroup().location

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('sku name standard or premium')
param skuName string = 'standard'

@description('sku family name.')
param skuFamily string = 'A'

@description('Azure AD tenant ID.')
param tenantId string 

@description('Enable RBAC on the key vault.')
param rbacAuthorization bool = false

@description('The vaults create mode to indicate whether the vault need to be recovered or not.')
@allowed([
  'default'
  'recover'
])
param createMode string = 'default'

@description('SubnetId of allowed network subnet.')
param subnetId string

@description('Tells what traffic can bypass network rules.')
param bypass string = 'AzureServices'

@description('Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = false

@description('Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = true

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

@description('Allowed IPs for the keyvault instance.')
param allowedIPs string

@description('Create secrets within the KeyVault.')
param createSecrets bool = false

@description('Keyvault secret names.')
param secretNames array

@description('Resource Id of the log analytics workspace')
param logAnalyticsId string

@description('enable allLogs diagnostics')
param allLogs bool = true

//Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultResourceName
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  properties: {
    sku:{
      name: skuName
      family: skuFamily
    }
    tenantId: tenantId
    enableRbacAuthorization: rbacAuthorization
    createMode: createMode
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: true
    networkAcls: {
      bypass: bypass
      defaultAction: 'Deny'
      ipRules: [
        {
          value: allowedIPs
        }
      ]
      virtualNetworkRules: [
        {
          id: subnetId
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
  resource keyVaultSecret 'secrets' = [for name in secretNames: if(createSecrets) {
    name: '${name}'
    properties: {
      value: '${name}'
    }
  }]
}

resource keyVaultDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyVaultLogAnalytics'
  scope: keyVault
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

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
