# shop-billing

- An invoice is final once sent; corrections are credit notes, never edits.
- Domain code takes a `Clock` from `app/shared/clock.py`, never `datetime.now()` (ADR 0011).
