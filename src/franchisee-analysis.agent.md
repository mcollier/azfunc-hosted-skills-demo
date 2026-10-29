---
name: franchisee-analysis
description: Analyze franchisee application against predefined criteria and recommend approval or rejection.
workflows:
  enabled: true
trigger:
  type: blob_trigger
  args:
    path: franchisee-applicants/{name}
    connection: AzureWebJobsStorage
---

# Franchisee Analysis

Analyze franchisee applications against predefined criteria and recommend approval or rejection.