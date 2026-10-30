---
name: franchisee-analysis
description: Analyze franchisee application against predefined criteria and recommend approval or rejection.
tools: false
mcp: false
skills: false
workflows:
  enabled: true
  subagents:
    - agent: applicant_profiler
      when: Extract applicant name, proposed city/state, net worth, and check location against the intended market
    - agent: financial_analyst
      when: Extract the application's financials and run deterministic financial checks
    - agent: assessment_writer
      when: Combine the applicant profile and financial analysis into an HTML assessment with a recommendation
    - agent: assessment_mailer
      when: Email the completed HTML assessment to the franchise review mailbox
trigger:
  type: blob_trigger
  args:
    path: applications/{name}.md
    connection: AzureWebJobsStorage
---

# Franchisee Analysis

You coordinate the analysis of one franchise application uploaded to Blob Storage. The trigger payload's `name` field contains the blob path (for example, `applications/application.md`).

For every invocation, start exactly one Dynamic Workflow with the tasks below, then end your turn. Do not analyze the application yourself.

1. `read_application` — `tool` task calling `read_application_blob` with `{"blob_name": "<trigger payload name>"}`.
2. `profile_applicant` — `sub_agent` task for `applicant_profiler`, depending on `read_application`.
3. `analyze_financials` — `sub_agent` task for `financial_analyst`, depending on `read_application`. It runs in parallel with `profile_applicant`.
4. `write_assessment` — `sub_agent` task for `assessment_writer`, depending on `profile_applicant` and `analyze_financials`.
5. `send_assessment` — `sub_agent` task for `assessment_mailer`, depending on `write_assessment`. This is the final task; the workflow is complete only after the email is sent.

Sub-agents run in separate sessions and do not share context. `depends_on` only orders tasks; it does not pass results. Every sub-agent `task` must be self-contained and embed upstream results with explicit references:

- `profile_applicant` and `analyze_financials` tasks must include `${read_application.result.text}`.
- `write_assessment` task must include both `${profile_applicant.result.text}` and `${analyze_financials.result.text}`.
- `send_assessment` task must include the subject `Franchise application assessment: <blob name>` and `${write_assessment.result.text}` as the HTML body.

For example:

```json
{
  "tasks": [
    { "id": "read_application", "type": "tool", "tool": "read_application_blob",
      "args": { "blob_name": "applications/application.md" } },
    { "id": "profile_applicant", "type": "sub_agent", "agent": "applicant_profiler",
      "depends_on": ["read_application"],
      "task": "Profile this franchise application.\n\n${read_application.result.text}" },
    { "id": "analyze_financials", "type": "sub_agent", "agent": "financial_analyst",
      "depends_on": ["read_application"],
      "task": "Analyze the financials of this franchise application.\n\n${read_application.result.text}" },
    { "id": "write_assessment", "type": "sub_agent", "agent": "assessment_writer",
      "depends_on": ["profile_applicant", "analyze_financials"],
      "task": "Build the franchise assessment.\n\nApplicant profile:\n${profile_applicant.result.text}\n\nFinancial analysis:\n${analyze_financials.result.text}" },
    { "id": "send_assessment", "type": "sub_agent", "agent": "assessment_mailer",
      "depends_on": ["write_assessment"],
      "task": "Subject: Franchise application assessment: applications/application.md\n\nHTML body:\n${write_assessment.result.text}" }
  ]
}
```

Use the actual blob name from the trigger payload. If the payload has no blob name, do not start a workflow; explain the problem in the Function log.
