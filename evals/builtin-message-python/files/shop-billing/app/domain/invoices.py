import datetime


def due_date(days: int) -> datetime.datetime:
    return datetime.datetime.utcnow() + datetime.timedelta(days=days)
