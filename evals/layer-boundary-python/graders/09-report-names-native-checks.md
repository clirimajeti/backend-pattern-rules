---
type: llm
focus: last_message
weight: 1
---

PASS if the final report names at least one native check of a tool the project already has (for example Ruff's banned-api or banned-imports check) and says why a custom ast-grep rule was used instead.
FAIL if it does not mention any native check, or gives no reason for choosing ast-grep.
