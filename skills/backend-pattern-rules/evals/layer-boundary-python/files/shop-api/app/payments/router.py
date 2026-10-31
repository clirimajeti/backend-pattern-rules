from fastapi import APIRouter

from . import repository

router = APIRouter(prefix="/payments")


@router.get("/{order_id}")
def payments_for(order_id: int):
    return repository.PaymentRepository().for_order(order_id)
