import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import tables
from app.db.database import get_db
from app.core.security import decode_access_token
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/matches", tags=["matches"])

class MatchCreate(BaseModel):
    title: str
    sport: str
    duration: float
    start_datetime: datetime
    location: str
    latitude: float
    longitude: float
    roster_size: int
    cost: float

@router.get("")
async def get_matches(
        current_user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    user_id = int(current_user["sub"])
    all_matches = db.query(tables.Match).all()
    user_matches = []

    for m in all_matches:
        is_host = (m.host_id == user_id)
        is_joined = any(
            p.user_id == user_id and p.status == "confirmed"
            for p in m.players
        )
        is_participant = any(p.user_id == user_id for p in m.players)
        if is_host or is_participant:
            user_matches.append({
                "match_id": m.id,
                "title": m.title,
                "start_datetime": m.start_datetime.replace(tzinfo=timezone.utc),
                "location": m.location,
                "cost": m.cost,
                "is_host": is_host,
                "is_cancelled": m.is_cancelled,
                "is_joined": is_joined,
                "joined": len(m.players),
                "roster_size": m.roster_size
            })
    return user_matches[::-1]

@router.post("/create")
async def create_match(match: MatchCreate, user: dict = Depends(decode_access_token), db: Session = Depends(get_db)):
    match_id = f"m_{uuid.uuid4().hex[:8]}"
    user_id = user["sub"]
    new_match = tables.Match(
        id=match_id,
        title=match.title,
        sport=match.sport,
        duration=match.duration,
        start_datetime=match.start_datetime,
        location=match.location,
        latitude=match.latitude,
        longitude=match.longitude,
        roster_size=match.roster_size,
        cost=match.cost,
        host_id=user_id
    )
    db.add(new_match)
    db.commit()
    return {"match_id": new_match.id}

@router.get("/{match_id}")
async def get_match_details(
        match_id: str,
        user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    match = db.query(tables.Match).filter(tables.Match.id == match_id).first()
    user_id = int(user["sub"])
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    # 1. Filter the list for the UI (only show confirmed players)
    # 2. Determine if the current viewer is one of those confirmed players
    active_players = []
    is_joined = False

    for p in match.players:
        if p.status == "confirmed":
            user_record = db.query(tables.User).filter(tables.User.id == p.user_id).first()
            username = user_record.display_name if user_record else "Unknown"
            active_players.append(username)

            # Check if this confirmed player is the person currently logged in
            if p.user_id == user_id:
                is_joined = True

    is_host = (match.host_id == user_id)

    return {
        "id": match.id,
        "title": match.title,
        "sport": match.sport,
        "start_datetime": match.start_datetime.replace(tzinfo=timezone.utc),
        "location": match.location,
        "latitude": match.latitude,
        "longitude": match.longitude,
        "cost": match.cost,
        "roster_size": match.roster_size,
        "duration": match.duration,
        "is_host": is_host,
        "current_roster": len(active_players),
        "player_list": active_players,
        "is_cancelled": match.is_cancelled,
        "is_joined": is_joined
    }

@router.post("/{match_id}/toggle-join")
async def toggle_join(match_id: str, user: dict = Depends(decode_access_token), db: Session = Depends(get_db)):
    user_id = int(user["sub"]) # Ensure user_id is an int

    match = db.query(tables.Match).filter(tables.Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    # Check if user is already in the match
    existing_entry = db.query(tables.MatchPlayer).filter(
        tables.MatchPlayer.match_id == match_id,
        tables.MatchPlayer.user_id == user_id
    ).first()

    if existing_entry:
        if existing_entry.status == "confirmed":
            # Soft leave: keep the record, change the status
            existing_entry.status = "left"
        else:
            # Re-joining
            existing_entry.status = "confirmed"
    else:
        # Check roster limit
        if len([p for p in match.players if p.status == "confirmed"]) >= match.roster_size:
            raise HTTPException(status_code=400, detail="Match is full")

        new_player = tables.MatchPlayer(match_id=match_id, user_id=user_id, status="confirmed") # Set status to confirmed
        db.add(new_player)

    db.commit()
    db.refresh(match) # Refresh the match object to get the latest player data

    active_players = []
    is_joined = False

    for p in match.players:
        if p.status == "confirmed":
            user_record = db.query(tables.User).filter(tables.User.id == p.user_id).first()
            username = user_record.display_name if user_record else "Unknown"
            active_players.append(username)

            if p.user_id == user_id:
                is_joined = True

    return {
        "status": "success",
        "current_roster": len(active_players),
        "player_list": active_players,
        "is_joined": is_joined # Add is_joined to the response
    }

@router.post("/{match_id}/toggle-cancel")
async def toggle_cancel(match_id: str, user: dict = Depends(decode_access_token), db: Session = Depends(get_db)):
    match = db.query(tables.Match).filter(tables.Match.id == match_id).first()
    user_id = int(user["sub"])
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.host_id != user_id: # Changed user["id"] to user["sub"] for consistency
        raise HTTPException(status_code=403, detail="Only the host can cancel this match")

    # The Python way to invert a boolean
    match.is_cancelled = not match.is_cancelled
    db.commit()
    return {"status": "success", "is_cancelled": match.is_cancelled}