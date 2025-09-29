from functools import lru_cache
from .store import Store

@lru_cache()
def get_store() -> Store:
    return Store()
