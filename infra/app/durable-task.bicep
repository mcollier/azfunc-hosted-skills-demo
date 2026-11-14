// ──────────────────────────────────────────────────────────────────────────────
// Module: Durable Task Scheduler + Task Hub
// ──────────────────────────────────────────────────────────────────────────────
// Deploys a Durable Task Scheduler (Consumption SKU) and its child Task Hub.
// No AVM module exists for Microsoft.DurableTask — raw resource definitions.
// ──────────────────────────────────────────────────────────────────────────────

@description('Name of the Durable Task Scheduler (3-64 alphanumeric + hyphens).')
param schedulerName string

@description('Name of the Task Hub (3-64 alphanumeric + hyphens).')
param taskHubName string

@description('Principal ID of the Function App managed identity.')
param managedIdentityPrincipalId string

@description('Azure region for deployment.')
param location string = resourceGroup().location

@description('IP allow list for the scheduler. Values can be IPv4, IPv6 or CIDR.')
param ipAllowlist string[] = ['0.0.0.0/0']

@description('Resource tags.')
param tags object = {}

var durableTaskDataContributorRoleDefinitionId = '0ad04412-c4d5-4796-b79c-f76d14c8d402'

// ─── Durable Task Scheduler ─────────────────────────────────────────────────
resource scheduler 'Microsoft.DurableTask/schedulers@2025-11-01' = {
  name: schedulerName
  location: location
  tags: tags
  properties: {
    ipAllowlist: ipAllowlist
    sku: {
      name: 'Consumption'
    }
  }
}

// ─── Task Hub (child of Scheduler) ─────────────────────────────────────────
resource taskHub 'Microsoft.DurableTask/schedulers/taskHubs@2025-11-01' = {
  parent: scheduler
  name: taskHubName
  properties: {}
}

resource taskHubDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(taskHub.id, managedIdentityPrincipalId, durableTaskDataContributorRoleDefinitionId)
  scope: taskHub
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', durableTaskDataContributorRoleDefinitionId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ─── Outputs ────────────────────────────────────────────────────────────────

@description('Resource ID of the Durable Task Scheduler.')
output schedulerResourceId string = scheduler.id

@description('Name of the Durable Task Scheduler.')
output schedulerName string = scheduler.name

@description('Endpoint URL of the Durable Task Scheduler.')
output schedulerEndpoint string = scheduler.properties.endpoint

@description('Resource ID of the Task Hub.')
output taskHubResourceId string = taskHub.id

@description('Name of the Task Hub.')
output taskHubName string = taskHub.name
