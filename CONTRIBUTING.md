# Contributing to Azure Functions Hosted Skills Demo

Thank you for your interest in contributing! Please read this guide before
submitting issues or pull requests.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```sh
   git clone https://github.com/YOUR-USERNAME/azfunc-hosted-skills-demo.git
   cd azfunc-hosted-skills-demo
   ```
3. Create a branch:
   ```sh
   git checkout -b feat/my-feature
   ```
4. Install dependencies:
   ```sh
   python -m venv src/.venv
   source src/.venv/bin/activate
   pip install -r src/requirements.txt
   ```
   Or open the repo in VS Code and choose **Reopen in Container** to use the
   devcontainer, which provisions Python, Azure CLI, Bicep, Azure Functions
   Core Tools, and Azurite for you.
5. Configure `src/local.settings.json` as described in the
   [README](README.md#2-configure-local-settings). This file is git-ignored
   and must never be committed. The same applies to `infra/main.bicepparam`,
   which holds environment-specific deployment values.
6. Make your changes
7. Verify locally:
   ```sh
   cd src && func start                       # agents start without errors
   ruff check src                             # lint is clean
   az bicep build --file infra/main.bicep     # infra still compiles
   ```

## Project Layout

| Path                     | What lives here                                               |
| ------------------------ | ------------------------------------------------------------- |
| `src/*.agent.md`         | Agent definitions: YAML front matter + system prompt          |
| `src/agents.config.yaml` | Shared runtime configuration                                  |
| `src/tools/`             | Python tools callable by agents (register in `_catalog.py`)   |
| `src/skills/`            | Hosted skills (`SKILL.md` with name/description front matter) |
| `src/mcp.json`           | MCP server declarations                                       |
| `infra/`                 | Bicep templates and `deploy.sh`                               |
| `ruff.toml`              | Lint configuration (pinned rule set)                          |

### Adding an agent

Create `src/<name>.agent.md` with `name` and `description` front matter, plus
either `builtin_endpoints` (HTTP) or a `trigger` block (Service Bus, timer,
etc.). CI validates that every `*.agent.md` and `SKILL.md` has parseable front
matter with both required keys.

### Adding a tool

Add a module under `src/tools/`, then register it in `src/tools/_catalog.py`.
Keep tools deterministic — agents are instructed never to fabricate inventory,
pricing, or coupon data, so the tool is the single source of truth.

## Pull Request Process

1. Update documentation for any new features
2. Keep secrets out of commits — no connection strings, keys, or tenant IDs
3. Ensure CI passes (Python lint/compile, Bicep build, agent validation)
4. Reference the related issue: `Closes #123`
5. Maintainers will review within a few business days

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `chore:` maintenance, dependencies
- `test:` adding or updating tests
- `refactor:` code restructure without behavior change

## Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml).
Include steps to reproduce, expected behavior, and your environment details.

## Requesting Features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml).
Describe the problem, your proposed solution, and any alternatives considered.
