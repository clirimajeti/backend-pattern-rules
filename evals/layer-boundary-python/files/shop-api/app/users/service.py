from app.users.repository import UserRepository


def get_user(user_id: int):
    if user_id <= 0:
        raise ValueError("user_id must be positive")
    return UserRepository().get(user_id)
