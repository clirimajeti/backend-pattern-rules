---
type: llm
focus: last_message
weight: 1
---

PASS if the final report maps the alias standard (STYLE.md rule 1) to the built-in PSAvoidUsingCmdletAliases and the Write-Host standard (rule 4) to the built-in PSAvoidUsingWriteHost.
A custom rule written for another standard (named parameters, [CmdletBinding()]) that also flags some of the same lines does not count against this.
FAIL if the report enforces rule 1 or rule 4 with a custom rule instead of the built-in one.
