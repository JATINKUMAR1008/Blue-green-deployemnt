from pydantic import BaseModel, Field

class ItemIn(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    price: float = Field(..., ge=0)

class Item(ItemIn):
    id: int
