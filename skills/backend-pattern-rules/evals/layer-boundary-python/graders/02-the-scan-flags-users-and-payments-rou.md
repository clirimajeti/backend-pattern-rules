---
type: llm
focus: trace
weight: 1
---

Running ast-grep scan over the original shop-api flags app/users/router.py (absolute import) and app/payments/router.py (relative import) and nothing else: not the services, not the TYPE_CHECKING import in app/orders/router.py, not the comment in app/orders/router.py, and not tests/
