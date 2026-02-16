from typing import Optional


class ContinueStream(Exception):
    def __init__(self, message: str = "", current_id: Optional[str] = None):
        super().__init__(message)
        self.current_id = current_id
