// Module for creating network security groups
// Parameters
@description('App service prefix.')
param nsgName string

@description('App service location.')
param location string = resourceGroup().location

// Resources
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
}

output nsgName string = nsg.name
