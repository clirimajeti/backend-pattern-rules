from sqlalchemy.orm import Session


def get_session() -> Session:
    raise NotImplementedError
