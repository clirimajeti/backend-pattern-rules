#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
# the eval sandbox has no network: ast-grep (the version the skill was verified with) and the pinned Ruff are installed here
(cd shop-api && npm install --no-save --no-package-lock --no-audit --no-fund --loglevel=error @ast-grep/cli@0.51.0 && uv venv --quiet .venv && uv pip install --quiet --python .venv ruff==0.7.0)
