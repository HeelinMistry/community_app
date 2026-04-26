from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ...db import database, tables
from ...core import security

router = APIRouter(prefix="/api/v1/auth", tags=["authentication"])


@router.post("/register")
def register(user_data: dict, db: Session = Depends(database.get_db)):
    db_user = db.query(tables.User).filter(tables.User.username == user_data['username']).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")

    new_user = tables.User(username=user_data['username'], display_name=user_data.get('display_name'))
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    cred = tables.Credential(user_id=new_user.id, hashed_password=security.hash_password(user_data['password']))
    db.add(cred)
    db.commit()
    return {"message": "User created successfully"}


@router.post("/login")
def login(user_data: dict, db: Session = Depends(database.get_db)):
    user = db.query(tables.User).filter(tables.User.username == user_data['username']).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    cred = db.query(tables.Credential).filter(tables.Credential.user_id == user.id).first()
    if not security.verify_password(user_data['password'], cred.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = security.create_access_token(data={"sub": user.username})
    return {"access_token": token, "token_type": "bearer"}