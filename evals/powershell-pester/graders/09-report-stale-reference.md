---
type: llm
focus: last_message
weight: 1
---

PASS if the final report notes that the agent doc points to a code-analysis.yml workflow that does not exist (PSScriptAnalyzer now runs in ci.yml), or otherwise flags that reference as out of date.
FAIL if it does not mention it.
