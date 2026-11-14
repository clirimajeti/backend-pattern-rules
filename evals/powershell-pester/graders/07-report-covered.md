---
type: llm
focus: last_message
weight: 1
---

PASS if the final report says the standards about the *-Object cmdlets and about calling commands through $SafeCommands are already enforced by Pester's own rules (Measure-ObjectCmdlets, Measure-SafeCommands), and it did not build new rules that duplicate them.
FAIL if it rebuilt either of them as a new rule, or does not say they are already enforced.
