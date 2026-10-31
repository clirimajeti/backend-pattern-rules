from app.orders.repository import OrderRepository


def list_orders():
    return OrderRepository().list()
