from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db import database, tables
from app.core import security

import time

router = APIRouter(prefix="/api/v1/auth", tags=["authentication"])


@router.post("/register")
def register(user_data: dict, db: Session = Depends(database.get_db)):
    # 1. Check if the username or email already exists in the Credentials table
    # Since username and email are now obscured, we query the 'Credential' table.
    if db.query(tables.Credential).filter(tables.Credential.username == user_data['username']).first():
        raise HTTPException(status_code=400, detail="Username taken")

    if db.query(tables.Credential).filter(tables.Credential.email == user_data['email']).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    try:
        # Generate the user_id using the current timestamp as requested
        user_id_timestamp = int(time.time())

        # 2. Create the Public User Profile
        # Only the non-sensitive display name is stored here.
        new_user = tables.User(
            id=user_id_timestamp,
            display_name=user_data.get('displayName')
        )
        db.add(new_user)

        # Ensure the user record exists before creating the credential record
        db.flush()

        # 3. Hash password and store sensitive/obtuse credentials
        hashed = security.hash_password(user_data['password'])

        new_cred = tables.Credential(
            user_id=user_id_timestamp,
            username=user_data['username'],
            email=user_data['email'],
            cell_number=user_data.get('cellNumber'),
            hashed_password=hashed
        )
        db.add(new_cred)

        # 4. Commit the transaction
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Registration failed")

    return {"detail": "User created", "success": True}


@router.post("/login")
def login(user_data: dict, db: Session = Depends(database.get_db)):
    # 1. Query the 'Credential' table for the username matching the login combo.
    cred = db.query(tables.Credential).filter(tables.Credential.username == user_data['username']).first()

    # 2. Verify existence and match the hashed password.
    if not cred or not security.verify_password(user_data['password'], cred.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    user_profile = db.query(tables.User).filter(tables.User.id == cred.user_id).first()

    # Safety check: Get the display_name or fallback if the profile doesn't exist
    display_name = user_profile.display_name if user_profile else "User"

    token = security.create_access_token(data={"sub": cred.user_id})
    return {
        "access_token": token,
        "token_type": "bearer",
        "display_name": display_name
    }