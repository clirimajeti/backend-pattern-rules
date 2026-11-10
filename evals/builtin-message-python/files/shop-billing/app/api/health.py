from datetime import datetime


def health() -> dict:
    return {"status": "ok", "time": datetime.now().isoformat()}
