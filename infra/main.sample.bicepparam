using 'main.bicep'

param toEmail = 'recipient@example.com'
param location = 'eastus2'
param environmentName = 'hosted-skills-demo'
param owner = 'owner@example.com'

param additionalModelDeployments = [
  {
    name: 'gpt-5.4'
    modelName: 'gpt-5.4'
    modelVersion: '2026-03-05'
    capacity: 50
  }
]
