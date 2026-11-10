from dataclasses import dataclass

from app.shared.db import get_session


@dataclass
class OrderRow:
    id: int
    total: int


class OrderRepository:
    def list(self) -> list[OrderRow]:
        return [OrderRow(**r) for r in get_session().execute("select id, total from orders")]
