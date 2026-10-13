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

router = APIRouter(prefix="/api/v1/reviews", tags=["reviews"])

class ReviewCreate(BaseModel):
    id: str
    comment: Optional[str]
    rating: float
    latitude: float
    longitude: float

@router.post("/product")
async def review_product(
        product_review: ReviewCreate,
        user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    """
        Allows a customer to submit a proof-of-service review/vouch
        with a photo and optional comment for a specific product.
        """
    # 1. Verify the product exists
    product = db.query(tables.Product).filter(tables.Product.id == product_review.id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    user_id = int(user["sub"])

    if product.user_id == user_id:
        raise HTTPException(status_code=403, detail="Creators cannot review their own products")

    new_review = tables.Review(
        product_id=product_review.id,
        user_id=user_id,
        rating=product_review.rating,
        comment=product_review.comment,
        latitude=product_review.latitude,
        longitude=product_review.longitude
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    return {"review_id": new_review.id}


@router.post("/{review_id}/upload-images")
async def upload_review_images(
        review_id: str,
        files: List[UploadFile] = File(...),
        user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    # 1. Verify product exists and belongs to the user
    product = db.query(tables.Product).filter(tables.Product.id == review_id).first()
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
            new_image = tables.ProductImage(
                product_id=review_id,
                image_url=image_url
            )
            db.add(new_image)
            uploaded_urls.append(image_url)

        db.commit()
        return {"images": uploaded_urls}

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to upload images: {str(e)}")


@router.get("/{review_id}")
async def get_review_detail(
        review_id: str,
        db: Session = Depends(get_db),
        current_user: dict = Depends(decode_access_token)
):
    """
    Retrieves a single product by its ID, including all related image URLs.
    """
    user_id = int(current_user["sub"])

    # 1. Query the product by ID
    product = db.query(tables.Product).filter(tables.Product.id == review_id).first()

    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    # 2. Extract all related image URLs from the product's images relationship
    image_urls = [img.image_url for img in product.images]

    # 3. Construct and return the full product details response
    return {
        "id": product.id,
        "title": product.title,
        "description": product.description,
        "tags": product.tags,
        "product_type": product.product_type,
        "latitude": product.latitude,
        "longitude": product.longitude,
        "service_radius": product.service_radius,
        "is_creator": product.user_id == user_id,
        "is_available": product.is_available,
        "image_urls": image_urls  # Full list of images linked to this product
    }