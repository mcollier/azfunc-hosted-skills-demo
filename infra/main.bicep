targetScope = 'subscription'

param mcpServerConfigName string = 'Office-365-Outlook-send-email-only'
param location string
@description('Value for the required "Owner" tag applied to all resources.')
param owner string
// param tags object = {}
param managedIdentityPrincipalId string = deployer().objectId
param deployerPrincipalId string = deployer().objectId
// param tenantId string = tenant().tenantId

@description('Name of an existing resource group to deploy into. Leave empty to create a new resource group named from environmentName.')
param existingResourceGroupName string = ''

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('Email address to send notifications to.')
param toEmail string

@minLength(1)
@maxLength(260)
@description('Service Bus queue name. Must match the queue_name in the order agent trigger.')
param serviceBusQueueName string = 'inbound-orders'

@description('Microsoft Foundry model deployment name.')
param foundryModel string = 'gpt-6.1-sol'

@description('Microsoft Foundry model name.')
param foundryModelName string = 'gpt-6.1-sol'

@description('Microsoft Foundry model version.')
param foundryModelVersion string = '2026-09-29'

@description('Microsoft Foundry deployment capacity.')
param foundryDeploymentCapacity int = 500

@description('Optional managed identity client ID to use when authenticating to the Office 365 Outlook MCP server. Leave empty to use the app-wide identity selection.')
param o365McpClientId string = ''


var tags = { 'azd-env-name': environmentName 
}
var abbreviations = loadJsonContent('./abbreviations.json')
var allTags = union(tags, { Owner: owner })
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var createResourceGroup = empty(existingResourceGroupName)
var resourceGroupName = createResourceGroup
  ? '${abbreviations.resourcesResourceGroups}${environmentName}'
  : existingResourceGroupName
var foundryAccountName = 'cog-${resourceToken}'
var foundryProjectName = '${foundryAccountName}-proj'
var functionAppName = '${abbreviations.webSitesFunctions}agents-${resourceToken}'
var deploymentStorageContainerName = 'app-package-${take(functionAppName, 32)}-${take(toLower(uniqueString(functionAppName, resourceToken)), 7)}'
var connectorGatewayName = 'cg-${resourceToken}'
var office365ConnectionName string = 'office365-outlook'
var schedulerName = 'dts-${resourceToken}'
var taskHubName = 'th-froyofoundry-${resourceToken}'
var serviceBusNamespaceName = '${abbreviations.serviceBusNamespaces}${resourceToken}'
// Identity-based connections require the hostname without the endpoint scheme, port, or path.
var serviceBusFullyQualifiedNamespace = split(split(split(serviceBus.outputs.serviceBusEndpoint, '//')[1], '/')[0], ':')[0]

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = if (createResourceGroup) {
  name: resourceGroupName
  location: location
  tags: allTags
}

module office365Connector 'app/connector-gateway.bicep' = {
  name: 'office365Connector'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rg]
  params: {
    location: location
    tags: allTags
    connectorGatewayName: connectorGatewayName
    connectionName: office365ConnectionName
    mcpServerConfigName: mcpServerConfigName
    managedIdentityPrincipalId: managedIdentityPrincipalId
    deployerPrincipalId: deployerPrincipalId
    tenantId: tenant().tenantId
  }
}

module storage 'br/public:avm/res/storage/storage-account:0.8.3' = {
  name: 'storage'
  scope: rg
  params: {
    name: '${abbreviations.storageStorageAccounts}${resourceToken}'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    dnsEndpointType: 'Standard'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    blobServices: {
      containers: [{ name: deploymentStorageContainerName }]
    }
    minimumTlsVersion: 'TLS1_2'
    location: location
    tags: tags
  }
}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-loganalytics'
  scope: rg
  params: {
    name: '${abbreviations.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
    dataRetention: 30
  }
}

module monitoring 'br/public:avm/res/insights/component:0.4.1' = {
  name: '${uniqueString(deployment().name, location)}-appinsights'
  scope: rg
  params: {
    name: '${abbreviations.insightsComponents}${resourceToken}'
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.resourceId
    disableLocalAuth: true
  }
}

module apiUserAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  name: 'apiUserAssignedIdentity'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbreviations.managedIdentityUserAssignedIdentities}agents-${resourceToken}'
  }
}

module serviceBus 'br/public:avm/res/service-bus/namespace:0.17.1' = {
  name: 'serviceBus'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: serviceBusNamespaceName
    location: location
    tags: allTags
    skuObject: {
      name: 'Standard'
    }
    zoneRedundant: false
    minimumTlsVersion: '1.2'
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
    queues: [
      {
        name: serviceBusQueueName
        roleAssignments: [
          {
            principalId: apiUserAssignedIdentity.outputs.principalId
            principalType: 'ServicePrincipal'
            roleDefinitionIdOrName: 'Azure Service Bus Data Receiver'
          }
        ]
      }
    ]
  }
}

module foundry './app/foundry.bicep' = {
  name: 'foundry'
  scope: rg
  params: {
    accountName: foundryAccountName
    projectName: foundryProjectName
    location: location
    tags: tags
    modelDeploymentName: foundryModel
    modelName: foundryModelName
    modelVersion: foundryModelVersion
    deploymentCapacity: foundryDeploymentCapacity
    managedIdentityPrincipalId: apiUserAssignedIdentity.outputs.principalId
    deployerPrincipalId: deployerPrincipalId
  }
}

module appServicePlan 'br/public:avm/res/web/serverfarm:0.1.1' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: '${abbreviations.webServerFarms}${resourceToken}'
    sku: {
      name: 'FC1'
      tier: 'FlexConsumption'
    }
    reserved: true
    location: location
    tags: tags
  }
}

module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: functionAppName
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.name
    appServicePlanId: appServicePlan.outputs.resourceId
    runtimeName: 'python'
    runtimeVersion: '3.13'
    storageAccountName: storage.outputs.name
    deploymentStorageContainerName: deploymentStorageContainerName
    identityId: apiUserAssignedIdentity.outputs.resourceId
    identityClientId: apiUserAssignedIdentity.outputs.clientId
    appSettings: {
      AZURE_FUNCTIONS_AGENTS_PROVIDER: 'foundry'
      FOUNDRY_PROJECT_ENDPOINT: foundry.outputs.projectEndpoint
      FOUNDRY_MODEL: foundry.outputs.modelDeploymentName
      AZURE_CLIENT_ID: apiUserAssignedIdentity.outputs.clientId
      TO_EMAIL: toEmail
      O365_MCP_SERVER_URL: office365Connector!.outputs.mcpEndpointUrl
      O365_MCP_CLIENT_ID: o365McpClientId
      ENABLE_MULTIPLATFORM_BUILD: 'true'
      DURABLE_TASK_SCHEDULER_CONNECTION_STRING: 'Endpoint=${durableTask.outputs.schedulerEndpoint};Authentication=ManagedIdentity;ClientId=${apiUserAssignedIdentity.outputs.clientId}'
      SERVICEBUS_CONNECTION__fullyQualifiedNamespace: serviceBusFullyQualifiedNamespace
      SERVICEBUS_CONNECTION__credential: 'managedidentity'
      SERVICEBUS_CONNECTION__clientId: apiUserAssignedIdentity.outputs.clientId
    }
  }
}

// ─── Durable Task Scheduler + Task Hub ──────────────────────────────────────
module durableTask 'app/durable-task.bicep' = {
  scope: rg
  params: {
    schedulerName: schedulerName
    taskHubName: taskHubName
    location: location
    tags: tags
  }
}


module rbac './app/rbac.bicep' = {
  name: 'rbacAssignments'
  scope: rg
  params: {
    storageAccountName: storage.outputs.name
    appInsightsName: monitoring.outputs.name
    managedIdentityPrincipalId: apiUserAssignedIdentity.outputs.principalId
    deployerPrincipalId: deployerPrincipalId
  }
}


output resourceGroupName string = resourceGroupName
output connectorGatewayName string = office365Connector.outputs.connectorGatewayName
// output connectionId string = connectorGateway.outputs.
output connectionAccessPolicyId string = office365Connector.outputs.connectionAccessPolicyId
output deployerConnectionAccessPolicyId string = office365Connector.outputs.deployerConnectionAccessPolicyId
output mcpEndpointUrl string = office365Connector.outputs.mcpEndpointUrl
output serviceBusNamespaceName string = serviceBus.outputs.name
output serviceBusNamespaceResourceId string = serviceBus.outputs.resourceId
output serviceBusFullyQualifiedNamespace string = serviceBusFullyQualifiedNamespace
output serviceBusQueueName string = serviceBusQueueName
