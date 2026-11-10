from datetime import datetime

from app.shared.clock import Clock


def refund_window_open(clock: Clock, paid_at: datetime) -> bool:
    return (clock.now() - paid_at).days < 30
