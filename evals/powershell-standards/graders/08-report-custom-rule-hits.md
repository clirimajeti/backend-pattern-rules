---
type: llm
focus: last_message
weight: 1
---

PASS if the final report says the custom [CmdletBinding()] rule flagged src/Public/Test-ServiceHealth.ps1 and no other file in the real code, and that its Pester tests passed.
FAIL if it lists other files for that rule, or says the rule or its tests could not be run.
