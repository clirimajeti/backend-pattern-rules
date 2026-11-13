#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
# the eval sandbox has no network: pwsh 7 with PSScriptAnalyzer and Pester must be installed on the machine
pwsh -NoProfile -NonInteractive -Command 'if (-not (Get-Module -ListAvailable PSScriptAnalyzer) -or -not (Get-Module -ListAvailable Pester)) { throw "PSScriptAnalyzer and Pester are needed" }'
