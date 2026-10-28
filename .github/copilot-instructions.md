# Azure Functions Hosted Skills Demo

This is a demo project that shows how to use Azure Functions Hosted Skills.

The agent is implemented as an Azure Function that is triggered by a Service Bus queue message. The agent uses the Microsoft Foundry models.

The function uses the agent defined in `src/main.agent.md` and the configuration defined in `src/agents.config.yaml`. 