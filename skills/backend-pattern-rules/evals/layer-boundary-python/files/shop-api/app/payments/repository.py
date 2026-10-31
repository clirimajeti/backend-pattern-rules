from app.shared.db import get_session


class PaymentRepository:
    def for_order(self, order_id: int):
        return get_session().execute("select * from payments where order_id = :id", {"id": order_id})
