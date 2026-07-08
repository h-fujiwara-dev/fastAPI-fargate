from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Item
from app.schemas import ItemCreate, ItemRead, ItemUpdate
from app.security import require_api_key

router = APIRouter(prefix="/items", tags=["items"], dependencies=[Depends(require_api_key)])


@router.post("", response_model=ItemRead, status_code=201)
async def create_item(payload: ItemCreate, db: AsyncSession = Depends(get_db)) -> Item:
    item = Item(**payload.model_dump())
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


@router.get("", response_model=list[ItemRead])
async def list_items(db: AsyncSession = Depends(get_db)) -> list[Item]:
    result = await db.execute(select(Item).order_by(Item.id))
    return list(result.scalars().all())


@router.get("/{item_id}", response_model=ItemRead)
async def get_item(item_id: int, db: AsyncSession = Depends(get_db)) -> Item:
    item = await db.get(Item, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@router.put("/{item_id}", response_model=ItemRead)
async def update_item(item_id: int, payload: ItemUpdate, db: AsyncSession = Depends(get_db)) -> Item:
    item = await db.get(Item, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    await db.commit()
    await db.refresh(item)
    return item


@router.delete("/{item_id}", status_code=204)
async def delete_item(item_id: int, db: AsyncSession = Depends(get_db)) -> None:
    item = await db.get(Item, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    await db.delete(item)
    await db.commit()
