#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
# pwsh 7 must be on the machine; the eval's own HOME starts empty, so the versions the skill was verified with are installed into it
pwsh -NoProfile -NonInteractive -Command '
  $ErrorActionPreference = "Stop"
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
  Install-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope CurrentUser
  Install-Module Pester -RequiredVersion 6.2.0 -Scope CurrentUser -SkipPublisherCheck
'
