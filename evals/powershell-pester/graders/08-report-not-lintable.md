---
type: llm
focus: last_message
weight: 1
---

PASS if the final report says the GitHub workflow instructions (milestones, pull requests, force-push, signing messages with the robot emoji) and the build and test instructions are not turned into lint rules because a linter cannot check them.
FAIL if it claims lint rules enforce any of them, or does not account for them at all.
