# Azure Functions Hosted Skills Demo

A demo showing how to build AI agents as **Azure Functions** using hosted skills,
tools, and Microsoft Foundry models.

Agents are defined declaratively in Markdown (`*.agent.md`) with YAML front
matter. The `azurefunctions-agents-runtime` package turns each one into a
running agent — complete with HTTP chat endpoints, a debug chat UI, Service Bus
triggers, Python tools, MCP servers, and reusable skills — from a three-line
`function_app.py`.

## What's in here

The demo models **Froyo Foundry**, a fictional frozen yogurt company, and ships
four agents:

| Agent                            | File                               | Trigger                            | What it does                                                                                                              |
| -------------------------------- | ---------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| My Agent                         | `src/main.agent.md`                | HTTP chat                          | Minimal "hello world" agent                                                                                               |
| Daily Dad Joke                   | `src/dad-joke.agent.md`            | HTTP chat + debug UI               | Tells dad jokes                                                                                                           |
| Order Fulfillment Decision Agent | `src/daily-orders.agent.md`        | `inbound-orders` Service Bus queue | Checks inventory, issues coupons on shortfall, recommends alternatives, and emails the customer                           |
| Franchisee Analysis (workflow)   | `src/franchisee-analysis.agent.md` | Blob in `applications/` container  | Plans a durable dynamic workflow that profiles the applicant, checks financials, writes an HTML assessment, and emails it |

The franchisee workflow uses internal-only subagents in `src/agents/`
(`applicant_profiler`, `financial_analyst`, `assessment_writer`,
`assessment_mailer`) and the `read_application_blob` workflow tool.

Supporting pieces:

| Path                                     | Purpose                                                                                                                                                                       |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/agents.config.yaml`                 | Shared runtime config (model, timeout)                                                                                                                                        |
| `src/tools/`                             | Python tools: `check_inventory`, `get_available_inventory`, `list_flavors`, `generate_coupon_code`, `check_financials`, `read_blob` / `read_application_blob` (workflow tool) |
| `src/agents/`                            | Workflow subagents used by the franchisee analysis agent                                                                                                                      |
| `src/skills/order-status-email/SKILL.md` | Hosted skill that composes the customer-facing HTML order email                                                                                                               |
| `src/mcp.json`                           | Office 365 Outlook MCP server used to send the email                                                                                                                          |
| `src/test.http`                          | Ready-to-run requests for the HTTP agents                                                                                                                                     |
| `infra/`                                 | Bicep templates for the Azure resources (incl. the O365 connector gateway)                                                                                                    |

## Prerequisites

- Python 3.14 (the devcontainer uses 3.14)
- [Azure Functions Core Tools v4](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep
- An Azure subscription with a Microsoft Foundry project and a deployed model
- An Azure Service Bus namespace with an `inbound-orders` queue for local order-agent runs
  (the Bicep deployment provisions these resources for Azure)
- [Azurite](https://learn.microsoft.com/azure/storage/common/storage-use-azurite)
  for local storage emulation

> The included devcontainer (`.devcontainer/`) installs all of the above. Open
> the repo in VS Code and choose **Reopen in Container** to skip manual setup.

## Getting started

### 1. Clone and install

```bash
git clone <your-fork-url> azfunc-hosted-skills-demo
cd azfunc-hosted-skills-demo

python -m venv src/.venv
source src/.venv/bin/activate
pip install -r src/requirements.txt
```

### 2. Configure local settings

Create `src/local.settings.json` (it is git-ignored — never commit it):

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "FOUNDRY_MODEL": "<your-model-deployment-name>",
    "SERVICEBUS_CONNECTION__fullyQualifiedNamespace": "<your-ns>.servicebus.windows.net",
    "O365_MCP_SERVER_URL": "<connector-gateway-mcp-url>",
    "O365_MCP_CLIENT_ID": "<app-registration-client-id>"
  }
}
```

Sign in so `DefaultAzureCredential` can acquire tokens:

```bash
az login
```

### 3. Run locally

```bash
cd src
func start
```

Then exercise the HTTP agents with `src/test.http` (VS Code REST Client), or:

```bash
curl -X POST http://localhost:7071/agents/dad_joke/chat \
  -H 'Content-Type: application/json' \
  -d '{"prompt": "tell me a joke about software engineering"}'
```

The dad joke agent also enables the built-in debug chat UI
(`builtin_endpoints.debug_chat_ui: true`); `func start` prints its URL along
with every other route it registers.

### 4. Exercise the order agent

The Order Fulfillment agent is triggered by messages on the `inbound-orders`
Service Bus queue. Send it a canonical order payload to see it work:

```json
{
  "orderId": "ORD-2002",
  "customer": {
    "firstName": "Grace",
    "lastName": "Hopper",
    "email": "grace.hopper@froyofoundry.example"
  },
  "items": [
    { "requestedQty": 3, "flavorId": "RRB" },
    { "requestedQty": 12, "flavorId": "BBB" },
    { "requestedQty": 2, "flavorId": "NPP" }
  ]
}
```

`BBB` has only 7 of the 12 requested on hand and `NPP` is out of stock, so this
order exercises the shortfall path: a 25% coupon plus alternative
recommendations. Stock levels come from the hardcoded catalog in
`src/tools/_catalog.py`.

Whatever publishes the message needs the **Azure Service Bus Data Sender** role
on the namespace (or queue).

### 5. Exercise the franchisee analysis workflow

The franchisee agent uses [dynamic workflows](https://learn.microsoft.com/azure/azure-functions/functions-hosted-skills-dynamic-workflows),
which require a Durable Task Scheduler. Locally, run the emulator and add
`TASKHUB_NAME` and `DURABLE_TASK_SCHEDULER_CONNECTION_STRING` to
`local.settings.json`:

```bash
docker run -d -p 8080:8080 -p 8082:8082 mcr.microsoft.com/dts/dts-emulator:latest
```

With Azurite and `func start` running, upload the sample application:

```bash
az storage container create -n applications --connection-string UseDevelopmentStorage=true
az storage blob upload -c applications -n application.md -f samples/application.md \
  --connection-string UseDevelopmentStorage=true --overwrite
```

The agent starts one workflow: `read_application` → (`profile_applicant` ∥
`analyze_financials`) → `write_assessment` → `send_assessment`. Track it in the
DTS dashboard at <http://localhost:8082>.

## Deploying to Azure

Create an `infra/main.bicepparam` for your environment:

```bicep
using 'main.bicep'

param connectorGatewayName = '<connector-gateway-name>'
param location = 'eastus2'
param owner = '<your-email>'
param environmentName = '<environment-name>'
param existingResourceGroupName = '<resource-group-name>'
param serviceBusQueueName = 'inbound-orders'
```

The deployment provisions a Standard Service Bus namespace and queue, configures
the Function App's identity-based connection, and grants its managed identity
the **Azure Service Bus Data Receiver** role on the queue. SAS authentication is
disabled; message publishers need Entra authentication and their own
**Azure Service Bus Data Sender** role.

`serviceBusQueueName` defaults to `inbound-orders`. If you override it, also
update `queue_name` in `src/daily-orders.agent.md` to match before publishing.
The deployment outputs include the namespace name, resource ID, fully qualified
namespace, and queue name.

The `foundryModel`, `foundryModelName`, `foundryModelVersion`, and
`foundryDeploymentCapacity` parameters configure the primary model, which
remains the Function App's `FOUNDRY_MODEL` default. Add other models through
`additionalModelDeployments` in `infra/main.bicepparam`:

```bicep
param additionalModelDeployments = [
  {
    name: 'gpt-5.4'
    modelName: 'gpt-5.4'
    modelVersion: '2026-03-05'
    capacity: 50
  }
]
```

Omit the list or set it to `[]` to provision only the primary model. Deployment
names must be unique, including the primary `foundryModel` name. Each additional
entry requires a model name, version, and positive capacity; all deployments use
the existing account and `GlobalStandard` SKU and are provisioned sequentially.
Check model availability and quota in your subscription and region before
deploying. The example adds `gpt-5.4` for the dad-joke agent while retaining
`gpt-6.1-sol` as the default; an agent's `model` override selects a deployment
by name.

Then deploy:

```bash
./infra/deploy.sh --what-if   # preview
./infra/deploy.sh             # deploy
```

Override the defaults with environment variables (`LOCATION`,
`DEPLOYMENT_NAME`). Then publish the function app:

```bash
cd src
func azure functionapp publish <your-function-app-name>
```

## How agents are defined

Each agent is a Markdown file whose front matter configures the runtime and
whose body is the system prompt:

```markdown
---
name: Daily Dad Joke
description: This agent tells epic dad jokes.
model: gpt-5.4
builtin_endpoints:
  debug_chat_ui: true
  chat_api: true
---

You are a dad joke assistant. When triggered, generate a new epic dad joke.
```

Swap `builtin_endpoints` for a `trigger` block to drive an agent from Service
Bus, a timer, or any other Functions binding — see `src/daily-orders.agent.md`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please also read our
[Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Found a vulnerability? See [SECURITY.md](SECURITY.md).

## License

Licensed under the [MIT License](LICENSE).

## Disclaimer

This is a demo. The inventory catalog is hardcoded, coupon generation is
simulated, and Froyo Foundry is not a real company. Review and harden before
using any of this in production.
