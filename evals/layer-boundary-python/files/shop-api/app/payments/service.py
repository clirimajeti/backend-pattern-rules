from .repository import PaymentRepository


def payments_for(order_id: int):
    return PaymentRepository().for_order(order_id)
