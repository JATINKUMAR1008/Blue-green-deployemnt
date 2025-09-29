from .models import ItemIn, Item

class Store:
    def __init__(self):
        self._items = {}
        self._id = 0

    def list(self):
        return [Item(id=i, **obj) for i, obj in self._items.items()]

    def create(self, payload: ItemIn) -> Item:
        self._id += 1
        self._items[self._id] = payload.model_dump()
        return Item(id=self._id, **payload.model_dump())

    def get(self, item_id: int) -> Item:
        data = self._items.get(item_id)
        if not data:
            raise KeyError
        return Item(id=item_id, **data)

    def delete(self, item_id: int) -> None:
        if item_id not in self._items:
            raise KeyError
        del self._items[item_id]
