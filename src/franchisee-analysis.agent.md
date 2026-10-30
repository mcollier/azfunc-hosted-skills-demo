---
name: franchisee-analysis
description: Analyze franchisee application against predefined criteria and recommend approval or rejection.
workflows:
  enabled: true
trigger:
  type: blob_trigger
  args:
    path: applications/{name}.md
    connection: AzureWebJobsStorage
---

# Franchisee Analysis

Analyze franchisee applications against predefined criteria and recommend approval or rejection.

When the blob triggers this agent:
1. Extract the blob name from the trigger metadata.
2. Call the `read_blob` tool using that name.
3. Read the provided franchise application and identify:
  - Applicant’s name
  - Proposed location’s city and state
  - Applicant’s net worth, including currency

Return these three fields in a short response. If a field is missing or unclear, say “Not provided” or “Unclear.” Do not guess.

Send an email summary to `michael.collier@live.com` with the extracted information.
