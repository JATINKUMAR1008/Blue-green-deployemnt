from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import logging

from .deps import get_store
from .store import Store
from .models import ItemIn, Item
from .version import get_version_info

logger = logging.getLogger("uvicorn")

app = FastAPI(title="Shop API", version=get_version_info()["version"])

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"status": "ok", **get_version_info()}

@app.get("/healthz/live")
def liveness():
    return {"live": True}

@app.get("/healthz/ready")
def readiness():
    return {"ready": True}

@app.get("/items", response_model=List[Item])
def list_items(store: Store = Depends(get_store)):
    return store.list()

@app.post("/items", response_model=Item, status_code=201)
def create_item(payload: ItemIn, store: Store = Depends(get_store)):
    item = store.create(payload)
    logger.info("created_item", extra={"item_id": item.id})
    return item

@app.get("/items/{item_id}", response_model=Item)
def get_item(item_id: int, store: Store = Depends(get_store)):
    try:
        return store.get(item_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Item not found")

@app.delete("/items/{item_id}", status_code=204)
def delete_item(item_id: int, store: Store = Depends(get_store)):
    try:
        store.delete(item_id)
        return {"deleted": True}
    except KeyError:
        raise HTTPException(status_code=404, detail="Item not found")
