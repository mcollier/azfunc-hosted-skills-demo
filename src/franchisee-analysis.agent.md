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

## Get the application data
When the blob triggers this agent:
1. Extract the blob name from the trigger metadata.
2. Call the `read_blob` tool using that name.

## Build the assessment
You need to complete the following steps to successfully build the assessment:
1. Read the provided franchise application and identify:
  - Applicant’s name
  - Proposed location’s city and state
  - Applicant’s net worth, including currency
2. Read the franchise application's to determine the applicant's financials, startup uses, monthly sales, and annual expenses as specified in the `check-financials` skill. Fan out the work when necessary.
3. Build the assessment using the `build-assessment` skill.
4. Verify the proposed location's city and state against the applicant's intended market.
5. Check for completeness and consistency of the financial information, including startup uses, monthly sales, and annual expenses.
6. Build the assessment based on the extracted information, financial analysis, and any identified gaps or inconsistencies.
7. Send the assessment via email with the HTML-based summary to `michael.collier@live.com` with the extracted information.
