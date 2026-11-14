#!/usr/bin/env bash
set -eu
# the real Pester repository, pinned: it has its own PSScriptAnalyzer rule module and agent docs that name its rules
git clone -q --filter=blob:none --no-checkout https://github.com/pester/Pester.git pester
git -C pester checkout -q 8c6fb875ba176af5247754098ef94d2449b169f9
# pwsh 7 must be on the machine; the eval's own HOME starts empty, so the versions the skill was verified with are installed into it
pwsh -NoProfile -NonInteractive -Command '
  $ErrorActionPreference = "Stop"
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
  Install-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope CurrentUser
  Install-Module Pester -RequiredVersion 6.2.0 -Scope CurrentUser -SkipPublisherCheck
'
