from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, Query
from geopy.distance import geodesic
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db import tables
from app.db.database import get_db

router = APIRouter(prefix="/api/v1/products", tags=["products"])

class ProductCreate(BaseModel):
    title: str
    description: Optional[str]
    tags: List[str]
    product_type: str
    latitude: float
    longitude: float
    service_radius: float  # In kilometers
    # image_url: str

@router.post("/create")
async def create_product(
        product: ProductCreate,
        user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    user_id = int(user["sub"])
    new_product = tables.Product(
        user_id=user_id,
        title=product.title,
        description=product.description,
        tags=product.tags,
        product_type=product.product_type,
        latitude=product.latitude,
        longitude=product.longitude,
        service_radius=product.service_radius,
        image_url='test'
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return {"product_id": new_product.id}


@router.get("")
async def get_nearby_products(
        lat: float = Query(...),
        lon: float = Query(...),
        db: Session = Depends(get_db),
        current_user: dict = Depends(decode_access_token)
):
    """
    Returns products whose area covers the user's current location.
    """
    user_id = int(current_user["sub"])

    # 1. Bounding Box Pre-filter
    # We use a static 50km buffer to capture any supplier that *could* # possibly cover the user's current point.
    buffer = 50.0 / 111.0

    candidates = db.query(tables.Product).filter(
        tables.Product.latitude.between(lat - buffer, lat + buffer),
        tables.Product.longitude.between(lon - buffer, lon + buffer)
    ).all()

    # 2. Point-in-Circle Filter
    user_loc = (lat, lon)
    nearby_products = []

    for p in candidates:
        # Distance from user to the supplier's center
        distance = geodesic(user_loc, (p.latitude, p.longitude)).km

        # A supplier is accessible if the user is within their service radius
        if distance <= p.service_radius:
            nearby_products.append({
                "id": p.id,
                "title": p.title,
                "description": p.description,
                "tags": p.tags,
                "distance_km": round(distance, 2),
                "latitude": p.latitude,
                "longitude": p.longitude,
                "image_url": p.image_url,
                "is_creator": p.user_id == user_id,
                "is_available": p.is_available
            })

    return nearby_products
