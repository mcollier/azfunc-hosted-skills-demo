#!/usr/bin/env bash
set -euo pipefail

# Resolve the repository root from this script's location, not the caller's working directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${REPO_ROOT}/src/.venv"

# Create the project virtual environment and install its Python dependencies.
# --clear recreates the venv, since src/.venv persists in the workspace across
# rebuilds and may have been built against a different Python version.
python -m venv --clear "${VENV_DIR}"
"${VENV_DIR}/bin/pip" install --disable-pip-version-check -r "${REPO_ROOT}/src/requirements.txt"

# Activate the virtual environment in future interactive Bash shells.
# Skip if the line already exists, so re-running the script doesn't duplicate it.
ACTIVATE_LINE="source ${VENV_DIR}/bin/activate"
if ! grep -qxF "${ACTIVATE_LINE}" ~/.bashrc 2>/dev/null; then
    echo "${ACTIVATE_LINE}" >> ~/.bashrc
fi

# pip install --disable-pip-version-check -r src/requirements.txt