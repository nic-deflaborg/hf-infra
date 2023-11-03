// Module for creating network security group rules
// Parameters
@description('Name of nsg rule.')
param nsgName string

@allowed([
  'Allow'
  'Deny'
])
@description('Whether network traffic is allowed or denied.')
param access string

@description('A description for this rule. Restricted to 140 chars.')
param nsgDescription string

@description('The direction of the rule.')
@allowed([
  'Inbound'
  'Outbound'
])
param direction string

@description('Network protocol this rule applies to.')
param protocol string

@description('The destination address prefixes. CIDR or destination IP ranges.')
param destinationAddressPrefix string

@description('The destination port ranges.')
param destinationPortRange string

@description('The priority of the rule.')
param priority int

@description('The CIDR or source IP range.')
param sourceAddressPrefix string

@description('The source port or range.')
param sourcePortRange string

// Resources
resource nsgRule 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  name: '${nsgName}/AllowHTTPSInBound'
  properties: {
    access: access
    description: nsgDescription
    destinationAddressPrefix: destinationAddressPrefix
    destinationPortRange: destinationPortRange
    direction: direction
    priority: priority
    protocol: protocol
    sourceAddressPrefix: sourceAddressPrefix
    sourcePortRange: sourcePortRange
  }
}
