targetScope = 'resourceGroup'

param connectorGatewayName string
param connectionName string = 'office365-outlook'
param managedIdentityPrincipalId string
param deployerPrincipalId string
param mcpServerConfigName string
param tenantId string
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

  resource office365Connection 'connections@2026-05-01-preview' = {
    name: connectionName
    properties: {
      connectorName: 'office365'
      displayName: 'Office 365 Outlook Connection'
    }

    resource office365ConnectionAccessPolicy 'accessPolicies@2026-05-01-preview' = {
      name: managedIdentityPrincipalId
      properties: {
        principal: {
          type: 'ActiveDirectory'
          identity: {
            objectId: managedIdentityPrincipalId
            tenantId: tenantId
          }
        }
      }
    }

    resource office365ConnectionDeployerAccessPolicy 'accessPolicies@2026-05-01-preview' = if (deployerPrincipalId != managedIdentityPrincipalId) {
      name: deployerPrincipalId
      properties: {
        principal: {
          type: 'ActiveDirectory'
          identity: {
            objectId: deployerPrincipalId
            tenantId: tenantId
          }
        }
      }
    }
  }

  resource office365McpServerConfig 'mcpserverconfigs@2026-05-01-preview' = {
    name: mcpServerConfigName
    properties: {
      state: 'Enabled'
      description: 'Microsoft Office 365 is a cloud-based service that is designed to help meet your organization\'s needs for robust security, reliability, and user productivity.'
      connectors: [
        {
          name: 'office365'
          connectionName: office365Connection.name
          displayName: 'Office 365 Outlook'
          description: ''
          operations: [
            {
              name: 'SendEmailV2'
              displayName: 'Send an email'
              description: 'This operation sends an email message.'
              userParameters: []
              agentParameters: [
                {
                  name: 'emailMessage'
                  schema: {
                    type: 'object'
                    properties: {
                      To: {
                        type: 'string'
                        format: 'email'
                        description: 'Specify email addresses separated by semicolons like someone@contoso.com'
                        required: true
                      }
                      Subject: {
                        type: 'string'
                        description: 'Specify the subject of the mail'
                        required: true
                      }
                      Body: {
                        type: 'string'
                        format: 'html'
                        description: 'Specify the body of the mail'
                        required: true
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
      policies: []
      settings: {
        textOnlyContent: true
      }
    }
  }
}

output connectorGatewayName string = connectorGateway.name
output connectorGatewayId string = connectorGateway.id
output connectionAccessPolicyId string = connectorGateway::office365Connection::office365ConnectionAccessPolicy.id // office365ConnectionAccessPolicy.id
output deployerConnectionAccessPolicyId string = connectorGateway::office365Connection::office365ConnectionDeployerAccessPolicy.id // office365ConnectionDeployerAccessPolicy.id
output mcpEndpointUrl string = connectorGateway::office365McpServerConfig.properties.mcpEndpointUrl //office365McpServerConfig.properties.mcpEndpointUrl
// output principalId string = connectorGateway.identity.principalId
