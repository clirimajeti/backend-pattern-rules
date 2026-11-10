# 11. Domain code takes a clock

Date: 2026-10-12
Status: Accepted

## Context

Due dates and order timestamps read the system clock directly, so tests had to patch `datetime` and month-end billing could not be replayed.

## Decision

Code in `app/domain/` never calls `datetime.now()` or `datetime.utcnow()`.
It takes a `Clock` (`app/shared/clock.py`) and calls `clock.now()`.
Only `SystemClock` in that module reads the real time.

## Consequences

Tests pass a fixed clock, and billing runs can be replayed for a past date.
