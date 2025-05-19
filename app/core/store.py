import logging


class Store:
    def __init__(self) -> None:
        from app.core.config import Config

        self.config = Config()
        self.logger = logging.getLogger("msu.store")

        # core
        from app.core.db import DatabaseAccessor
        self.db = DatabaseAccessor(self)
