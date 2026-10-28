#!/usr/bin/env bash
#
# Deploys infra/main.bicep at subscription scope.
#
# Usage:
#   ./deploy.sh                 # deploy
#   ./deploy.sh --what-if       # preview changes without deploying
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/main.bicep"
PARAM_FILE="${SCRIPT_DIR}/main.bicepparam"

LOCATION="${LOCATION:-eastus2}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-hosted-skills-$(date -u +%Y%m%d-%H%M%S)}"

if ! az account show >/dev/null 2>&1; then
  echo "Not logged in to Azure. Run 'az login' first." >&2
  exit 1
fi

echo "Subscription: $(az account show --query name -o tsv)"
echo "Location:     ${LOCATION}"
echo "Deployment:   ${DEPLOYMENT_NAME}"
echo

if [[ "${1:-}" == "--what-if" ]]; then
  az deployment sub what-if \
    --name "${DEPLOYMENT_NAME}" \
    --location "${LOCATION}" \
    --template-file "${TEMPLATE_FILE}" \
    --parameters "${PARAM_FILE}"
  exit 0
fi

az deployment sub create \
  --name "${DEPLOYMENT_NAME}" \
  --location "${LOCATION}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters "${PARAM_FILE}"

echo
echo "Outputs:"
az deployment sub show \
  --name "${DEPLOYMENT_NAME}" \
  --query properties.outputs \
  -o json
