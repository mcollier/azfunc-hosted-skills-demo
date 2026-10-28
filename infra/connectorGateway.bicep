targetScope = 'resourceGroup'

param connectorGatewayName string
param location string = resourceGroup().location
param tags object = {}

resource connectorGateway 'Microsoft.Web/connectorGateways@2026-05-01-preview' = {
  name: connectorGatewayName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

output name string = connectorGateway.name
output id string = connectorGateway.id
output principalId string = connectorGateway.identity.principalId
