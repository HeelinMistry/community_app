from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .db import database, tables
from .api.v1 import auth

# Create tables on startup
tables.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Community Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Tighten this for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)

@app.get("/")
def health_check():
    return {"status": "online"}