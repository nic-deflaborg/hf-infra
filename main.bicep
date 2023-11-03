// Parameters
@description('Location of resource group.')
param resourceGroupLocation string

@description('resource tagging system owner')
param systemOwner string

@description('resource tagging system responsible')
param systemResp string

@description('Environment')
param env string

@description('Name of the existing vnet.')
param vnetName string 

@description('Name of the existing subnet for ASEv3.')
param aseSubnetName string

@description('Name of the resource group for the vnet.')
param vnetRg string = 'RG-Network'

@description('Name of Key vault resource.')
param keyVaultResourceName string = 'kv-lab-${env}-lab'

//@description('Apply Keyvault access policy permissions for app services.')
//param applyAccessPolicy bool = false

@description('Storage account naming prefix.')
param stgAcc string = 'salab'

@description('List of Allowed IPs from the lab network.')
param IPWhitelist string

@description('List of web app service names.')
param appServiceNames array

@description('KeyVault secret names.')
param labSecretNames array

@description('Service bus queue names.')
param queueNames array

@description('AD login name.')
param aadLoginName string

@description('AD login SID.')
param aadLoginSid string

// Variables
//Get app service environment subnet reference
var aseSubnetRef = '${vnetlab.id}/subnets/${aseSubnetName}'

// Optional apply keyvault access policy to the keyvault instance - resolves issue with access policy config
//var accessPolicies = applyAccessPolicy ? [] : reference(resourceId('Microsoft.KeyVault/vaults', keyVaultResourceName), '2019-09-01').accessPolicies

// Resources
// Retrieving existing vnet name
resource vnetlab 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRg)
}

// Creating app service environment
module asev3 'modules/asev3.bicep' = {
  name: 'labAppServiceEnvironent'
  scope: resourceGroup()
  params: {
    asev3Name: 'ase-${env}-lab'
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    vnetId: aseSubnetRef                  
    subnetRef: aseSubnetRef
  }
}

// Creating app service plan
module labAppServicePlan 'modules/appserviceplan.bicep' = {
  name: 'labAppSericePlan'
  scope: resourceGroup()
  params: {
    appServicePlanName:'asp-${env}-lab'
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    hostingEnvironmentProfileName: asev3.outputs.asev3Name
  }
}

// Creating log analytics workspace
module labLogAnalytics 'modules/loganalytics.bicep' = {
  name: 'labLogAnalyticsWorkspace'
  params: {
    logAnalyticsNamespaceName: 'law-${env}-lab'
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    skuName: 'Standard'
  }
}

// Creating app services 
@batchSize(4) // Create in batches to avoid exceeding API call limits
//TODO: Create keyvault first in portal manually due to access policy dependency
module labAppServices 'modules/appservice.bicep' = [for name in appServiceNames: {
    name: name
    scope: resourceGroup()
    params: {
      appName: 'as-${env}-${name}'
      kind: 'web'
      location: resourceGroupLocation
      env: env
      systemOwner: systemOwner
      systemResp: systemResp
      appServicePlanId: labAppServicePlan.outputs.appServicePlanName
      hostingEnvironmentProfileName: asev3.outputs.asev3Name
      logAnalyticsId: labLogAnalytics.outputs.logAnalyticsId
      keyVaultAccessPolicy: true
      keyVaultResourceName: keyVaultResourceName
      secretPermissions: 'get'
    }
    dependsOn: [
      labKeyVault
    ]
  }]

// Creating Function app
module labFunctionApp 'modules/functionapp.bicep' = {
  name: 'labFunctionApp'
  params: {
    appName: 'fa-${env}-lab'
    kind: 'functionapp'
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    appServicePlanId: labAppServicePlan.outputs.appServicePlanName
    hostingEnvironmentProfileName: asev3.outputs.asev3Name
    logAnalyticsId: labLogAnalytics.outputs.logAnalyticsId
    keyVaultAccessPolicy: true
    keyVaultResourceName: keyVaultResourceName
    secretPermissions: 'get'
  }
  dependsOn: [
    labKeyVault
  ]
}
resource labFunctionAppSettings 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'fa-${env}-lab/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: labFunctionApp.outputs.instrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
    labappusername: 'admin'
    labappassword: 'P@ssword123'
  }
  dependsOn: [
    labKeyVault
  ]
}

// Creating KeyVault
module labKeyVault 'modules/keyvault.bicep' = {
  name: 'labKeyvault'
  scope: resourceGroup()
  params: {
    keyVaultResourceName: keyVaultResourceName
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    tenantId: subscription().tenantId
    subnetId: aseSubnetRef
    allowedIPs: IPWhitelist
    createSecrets: true
    secretNames: labSecretNames
    logAnalyticsId: labLogAnalytics.outputs.logAnalyticsId
  }
}

// Creating Data Factory 
module labDataFactory 'modules/datafactory.bicep' = {
  name: 'labDataFactory'
  params: {
    dataFactoryName: 'df-lab-${env}-lab'
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    identity: 'SystemAssigned'
  }
}

// Creating Datalake storage account
module labDataLake 'modules/storage.bicep' = {
  name: 'labDataLake'
  params: {
    storageAccountName: '${stgAcc}${env}lab'
    location: 'North Europe'
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    networkAccess: 'Allow'
    isHnsEnabled: true
    }
  }

// Creating SQL server & database
module labSQL 'modules/sqlserver.bicep' = {
  name: 'labSQLServer'
  params: {
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    servername: 'db-lab-${env}-lab-ne'
    dbname: 'sqllabdb'
    sku: 'Basic'
    aadLoginName: aadLoginName
    aadLoginSid: aadLoginSid
    publicNetworkAccess: 'enabled'
    subnetRef: aseSubnetRef
    logAnalyticsId: labLogAnalytics.outputs.logAnalyticsId
  }
}

// Creating Service Bus namespace and queues
module labServiceBus 'modules/servicebus.bicep' = {
  name: 'labServiceBusNamespace'
  params: {
    location: resourceGroupLocation
    systemOwner: systemOwner
    systemResp: systemResp
    env: env
    serviceBusNamespaceName: 'sb-${env}-lab'
    queueNames: queueNames
    logAnalyticsId: labLogAnalytics.outputs.logAnalyticsId
  }
}

// Creating network resources
module nsgASE 'modules/nsg.bicep' = {
  name: 'aseNSG'
  scope: resourceGroup(vnetRg)
  params: {
    nsgName: 'nsg-${env}-ase'
    location: resourceGroupLocation
  }
}

module nsgASEHttpsRule 'modules/nsgrule.bicep' = {
  name: 'AllowHTTPSInBound'
  scope: resourceGroup(vnetRg)
  params: {
    nsgName: nsgASE.outputs.nsgName
    access: 'Allow'
    nsgDescription: 'Allow HTTPS Inbound'
    destinationAddressPrefix: '*'
    destinationPortRange: '443'
    direction: 'Inbound'
    priority: 100
    protocol: 'TCP'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

module nsgDF 'modules/nsg.bicep' = {
  name: 'nsg-df'
  scope: resourceGroup(vnetRg)
  params: {
    nsgName: 'nsg-${env}-df'
    location: resourceGroupLocation
  }
}


// Outputs
output environmentOutput object = environment()

module windowsVM 'modules/winvm.bicep' = {
  name: 'winVM-01'
  params: {
    vmName: 'winVM-01'
    location: resourceGroupLocation
    adminUsername: 'admin'
    adminPassword: 'P@ssword1234567'
  }
}
