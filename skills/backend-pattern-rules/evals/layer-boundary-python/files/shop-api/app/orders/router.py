from typing import TYPE_CHECKING

from fastapi import APIRouter

from app.orders import service

if TYPE_CHECKING:
    from app.orders.repository import OrderRow

router = APIRouter(prefix="/orders")


@router.get("/")
def list_orders() -> "list[OrderRow]":
    # The repository is only reached through app.orders.service.
    return service.list_orders()
