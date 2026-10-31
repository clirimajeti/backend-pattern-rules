from app.shared.db import get_session


class UserRepository:
    def get(self, user_id: int):
        return get_session().get("users", user_id)
