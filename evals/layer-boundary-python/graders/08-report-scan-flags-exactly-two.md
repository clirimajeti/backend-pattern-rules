---
type: llm
focus: last_message
weight: 1
---
PASS if the final report says the ast-grep scan over the real code flagged app/users/router.py and app/payments/router.py and not app/orders/router.py (its repository import is type-only), and that ast-grep test passed with recorded snapshots.
FAIL if it says ast-grep could not be run, or lists other files.
