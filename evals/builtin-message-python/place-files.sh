#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
# the eval sandbox has no network, so the pinned Ruff goes into a local .venv here, before the agent starts
(cd shop-billing && uv venv --quiet .venv && uv pip install --quiet --python .venv ruff==0.7.0)
