from fastapi import APIRouter

from app.users import service
from app.users.repository import UserRepository

router = APIRouter(prefix="/users")


@router.get("/{user_id}")
def get_user(user_id: int):
    return service.get_user(user_id)


@router.get("/{user_id}/raw")
def get_user_raw(user_id: int):
    return UserRepository().get(user_id)
