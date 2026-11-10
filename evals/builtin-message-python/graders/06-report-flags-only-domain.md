---
type: llm
focus: last_message
weight: 1
---
PASS if the final report says Ruff, run with the configuration the run wrote, flagged app/domain/orders.py and app/domain/invoices.py and did not flag app/shared/clock.py, app/api/health.py or app/domain/refunds.py.
FAIL if it says Ruff could not be run, or lists other files.
