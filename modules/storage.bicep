// Module for creating storage account
// Parameters
@description('Storage account name')
param storageAccountName string

@description('Storage account resource group location')
param location string

@description('System owner resource tagging')
param systemOwner string

@description('System responsible resource tagging')
param systemResp string

@description('Environment')
param env string

@description('Storage sku name')
param skuName string = 'Standard_LRS'

@description('Storage account kind')
param storageKind string = 'StorageV2'

@description('Tells what traffic can bypass network rules.')
param bypass string = 'AzureServices'

@description('Enable hierachical namespaces for datalake storage')
param isHnsEnabled bool = false

@description('Access to storage account')
param networkAccess string = 'Deny'

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  tags: {
    system_owner: systemOwner
    system_responsible: systemResp
    env: env
  }
  sku: {
    name: skuName
  }
  kind: storageKind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: isHnsEnabled
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: bypass
      defaultAction: networkAccess
    }
  }
}
