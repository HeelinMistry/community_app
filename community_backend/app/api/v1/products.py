from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from geopy.distance import geodesic
from pydantic import BaseModel
from sqlalchemy.orm import Session
import shutil
import uuid

from app.core.security import decode_access_token
from app.db import tables
from app.db.database import get_db
from app.db.tables import ReviewState

router = APIRouter(prefix="/api/v1/products", tags=["products"])

class ProductCreate(BaseModel):
    title: str
    description: Optional[str]
    tags: List[str]
    product_type: str
    latitude: float
    longitude: float
    service_radius: float  # In kilometers

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
        service_radius=product.service_radius
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
                "is_creator": p.user_id == user_id,
                "is_available": p.is_available
            })

    return nearby_products

@router.post("/{product_id}/upload-images")
async def upload_product_images(
        product_id: str,
        files: List[UploadFile] = File(...),
        user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    # 1. Verify product exists and belongs to the user
    product = db.query(tables.Product).filter(tables.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    user_id = int(user["sub"])
    if product.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to modify this product")

    uploaded_urls = []

    try:
        for file in files:
            file_ext = file.filename.split(".")[-1] if file.filename else "jpg"
            file_name = f"p_{uuid.uuid4().hex[:8]}.{file_ext}"
            file_path = f"app/static/uploads/{file_name}"

            # Save file to disk
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

            image_url = f"{file_name}"

            # Create database record for the image
            new_image = tables.Images(
                product_id=product_id,
                image_url=image_url
            )
            db.add(new_image)
            uploaded_urls.append(image_url)

        db.commit()
        return {"images": uploaded_urls}

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to upload images: {str(e)}")


@router.get("/{product_id}")
async def get_product_detail(
        product_id: str,
        db: Session = Depends(get_db),
        current_user: dict = Depends(decode_access_token)
):
    """
    Retrieves a single product by its ID, including all related image URLs.
    Includes categorized review IDs if the requester is the product creator.
    """
    user_id = int(current_user["sub"])

    # 1. Query the product by ID
    product = db.query(tables.Product).filter(tables.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    is_creator = product.user_id == user_id

    # 2. Initialize categorized lists
    review_pending, review_approved, review_rejected = [], [], []

    # 3. Populate review arrays in a single efficient pass if user is the creator
    if is_creator:
        for r in product.reviews:
            # Handle both string or Enum database storage seamlessly
            state = r.state.value if hasattr(r.state, "value") else str(r.state).lower()

            if state == ReviewState.PENDING:
                review_pending.append(r.id)
            elif state == ReviewState.ACCEPTED:
                review_approved.append(r.id)
            elif state == ReviewState.REJECTED:
                review_rejected.append(r.id)

    # 4. Return clean, structured payload
    return {
        "id": product.id,
        "title": product.title,
        "description": product.description,
        "tags": product.tags,
        "product_type": product.product_type,
        "latitude": product.latitude,
        "longitude": product.longitude,
        "service_radius": product.service_radius,
        "is_creator": is_creator,
        "is_available": product.is_available,
        "image_urls": [img.image_url for img in product.images],
        "review_pending": review_pending,
        "review_approved": review_approved,
        "review_rejected": review_rejected,
    }