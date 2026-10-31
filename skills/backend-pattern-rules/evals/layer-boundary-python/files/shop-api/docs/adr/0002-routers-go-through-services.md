# 2. Routers go through services

Date: 2026-08-02
Status: Accepted

## Context

Routers that queried repositories directly skipped validation and transaction handling, and their tests needed a database.

## Decision

A feature's `router.py` never imports from a `repository` module, its own or another feature's.
It calls the feature's `service.py`, which owns validation, transactions and repository access.
Imports used only for type hints (inside `if TYPE_CHECKING:`) are fine.

## Consequences

Every new endpoint needs a service function. Router tests mock the service, not the database.
