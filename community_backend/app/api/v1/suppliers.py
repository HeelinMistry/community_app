from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from geopy.distance import geodesic
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db import tables
from app.db.database import get_db

router = APIRouter(prefix="/api/v1/suppliers", tags=["suppliers"])

class SupplierCreate(BaseModel):
    business_name: str
    description: Optional[str]
    latitude: float
    longitude: float
    service_radius: float  # In kilometers
    category: str


@router.get("")
async def get_nearby_suppliers(
        lat: float = Query(...),
        lon: float = Query(...),
        user_radius: float = Query(5.0),  # User's search range
        db: Session = Depends(get_db),
        current_user: dict = Depends(decode_access_token)
):
    """
    Returns suppliers whose service area overlaps with the user's location + search radius.
    """
    # 1. Bounding Box Pre-filter (approx 1 degree = 111km)
    # We add the max possible service radius to the delta to be safe
    buffer = (user_radius + 50.0) / 111.0

    candidates = db.query(tables.Supplier).filter(
        tables.Supplier.latitude.between(lat - buffer, lat + buffer),
        tables.Supplier.longitude.between(lon - buffer, lon + buffer)
    ).all()

    # 2. Geometric Intersection Filter
    user_loc = (lat, lon)
    nearby_suppliers = []

    for s in candidates:
        distance = geodesic(user_loc, (s.latitude, s.longitude)).km
        # Logic: Circles overlap if distance <= sum of radii
        if distance <= (user_radius + s.service_radius):
            nearby_suppliers.append({
                "id": s.id,
                "business_name": s.business_name,
                "description": s.description,
                "category": s.category,
                "distance_km": round(distance, 2)
            })

    return nearby_suppliers


@router.post("/create")
async def create_supplier(
        supplier: SupplierCreate,
        user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    user_id = int(user["sub"])
    # Note: Use your preferred ID strategy (string or int as per schema)
    new_supplier = tables.Supplier(
        user_id=user_id,
        business_name=supplier.business_name,
        description=supplier.description,
        latitude=supplier.latitude,
        longitude=supplier.longitude,
        service_radius=supplier.service_radius,
        category=supplier.category
    )
    db.add(new_supplier)
    db.commit()
    db.refresh(new_supplier)
    return {"supplier_id": new_supplier.id}


@router.get("/{supplier_id}")
async def get_supplier_details(supplier_id: int, db: Session = Depends(get_db)):
    supplier = db.query(tables.Supplier).filter(tables.Supplier.id == supplier_id).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")

    return {
        "id": supplier.id,
        "business_name": supplier.business_name,
        "description": supplier.description,
        "latitude": supplier.latitude,
        "longitude": supplier.longitude,
        "service_radius": supplier.service_radius,
        "category": supplier.category
    }