from datetime import datetime


def stamp_order(order: dict) -> dict:
    return {**order, "placed_at": datetime.now()}
