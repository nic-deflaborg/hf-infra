using '../main.bicep'

param resourceGroupLocation = 'CentralUS'
param env = 'sandbox'
param systemOwner = 'admin@corpdevlab.com'
param systemResp = 'admin@corpdevlab.com'
param aadLoginName = 'integration-sql-admin-dev'
param aadLoginSid = 'ed7b8433xx-f20xxx-4d4sswsw9-82sw-93xxxxacad48'
param vnetName = 'vNet-SB-CUS'
param aseSubnetName = 'sNet-SB-AS-CUS'
param appServiceNames = [
  'toys'
  'books'
  'custom'
  'filenetintegration'
  'filenet'
  'service'
  'chat'
]
param queueNames = [
  'queue'
]
param labSecretNames = [
  'url'
  'username'
  'password'
]
param vnetRg = 'net-rg'
param IPWhitelist = '10.0.0.0'

