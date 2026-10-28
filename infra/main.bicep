targetScope = 'subscription'

param connectorGatewayName string
param connectionName string = 'office365-outlook'
param mcpServerConfigName string = 'Office-365-Outlook-send-email-only'
param location string
@description('Value for the required "Owner" tag applied to all resources.')
param owner string
param tags object = {}
param managedIdentityPrincipalId string = deployer().objectId
param deployerPrincipalId string = deployer().objectId
param tenantId string = tenant().tenantId

@description('Name of an existing resource group to deploy into. Leave empty to create a new resource group named from environmentName.')
param existingResourceGroupName string = ''

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

var abbreviations = loadJsonContent('./abbreviations.json')
var allTags = union(tags, { Owner: owner })
var createResourceGroup = empty(existingResourceGroupName)
var resourceGroupName = createResourceGroup
  ? '${abbreviations.resourcesResourceGroups}${environmentName}'
  : existingResourceGroupName

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = if (createResourceGroup) {
  name: resourceGroupName
  location: location
  tags: allTags
}

module connectorGateway 'connectorGateway.bicep' = {
  name: 'connectorGateway'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rg]
  params: {
    connectorGatewayName: connectorGatewayName
    location: location
    tags: allTags
  }
}

module office365 'office365Connection.bicep' = {
  name: 'office365Connection'
  scope: resourceGroup(resourceGroupName)
  params: {
    connectorGatewayName: connectorGateway.outputs.name
    connectionName: connectionName
    mcpServerConfigName: mcpServerConfigName
    managedIdentityPrincipalId: managedIdentityPrincipalId
    deployerPrincipalId: deployerPrincipalId
    tenantId: tenantId
  }
}

output resourceGroupName string = resourceGroupName
output connectorGatewayName string = connectorGateway.outputs.name
output connectionId string = office365.outputs.connectionId
output connectionAccessPolicyId string = office365.outputs.connectionAccessPolicyId
output deployerConnectionAccessPolicyId string = office365.outputs.deployerConnectionAccessPolicyId
output mcpEndpointUrl string = office365.outputs.mcpEndpointUrl
