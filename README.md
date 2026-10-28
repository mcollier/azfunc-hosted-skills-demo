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
three agents:

| Agent | File | Trigger | What it does |
| --- | --- | --- | --- |
| My Agent | `src/main.agent.md` | HTTP chat | Minimal "hello world" agent |
| Daily Dad Joke | `src/dad-joke.agent.md` | HTTP chat + debug UI | Tells dad jokes |
| Order Fulfillment Decision Agent | `src/daily-orders.agent.md` | `inbound-orders` Service Bus queue | Checks inventory, issues coupons on shortfall, recommends alternatives, and emails the customer |

Supporting pieces:

| Path | Purpose |
| --- | --- |
| `src/agents.config.yaml` | Shared runtime config (model, timeout) |
| `src/tools/` | Python tools: `check_inventory`, `get_available_inventory`, `list_flavors`, `generate_coupon_code` |
| `src/skills/order-status-email/SKILL.md` | Hosted skill that composes the customer-facing HTML order email |
| `src/mcp.json` | Office 365 Outlook MCP server used to send the email |
| `src/test.http` | Ready-to-run requests for the HTTP agents |
| `infra/` | Bicep templates for the Azure resources (incl. the O365 connector gateway) |

## Prerequisites

- Python 3.13 or later (`azurefunctions-agents-runtime` requires >= 3.13; the
  devcontainer uses 3.14)
- [Azure Functions Core Tools v4](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep
- An Azure subscription with a Microsoft Foundry project and a deployed model
- An Azure Service Bus namespace with an `inbound-orders` queue (for the order agent)
- [Azurite](https://learn.microsoft.com/azure/storage/common/storage-use-azurite) for local storage emulation

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

## Deploying to Azure

Create an `infra/main.bicepparam` for your environment:

```bicep
using 'main.bicep'

param connectorGatewayName = '<connector-gateway-name>'
param location = 'eastus2'
param owner = '<your-email>'
param environmentName = '<environment-name>'
param existingResourceGroupName = '<resource-group-name>'
```

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
