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

def _format_match_response(match: tables.Match, user_id: int):
    """Helper function to format a single match object for response."""
    is_host = (match.host_id == user_id)
    
    # Check if the user is a confirmed participant
    is_joined = any(p.user_id == user_id and p.status == "confirmed" for p in match.players)

    # Count confirmed players
    confirmed_players_count = sum(1 for p in match.players if p.status == "confirmed")

    return {
        "match_id": match.id,
        "title": match.title,
        "start_datetime": match.start_datetime.replace(tzinfo=timezone.utc),
        "location": match.location,
        "cost": match.cost,
        "is_host": is_host,
        "is_cancelled": match.is_cancelled,
        "is_joined": is_joined,
        "joined": confirmed_players_count,
        "roster_size": match.roster_size
    }

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
        is_participant = any(p.user_id == user_id for p in m.players)
        
        if is_host or is_participant:
            user_matches.append(_format_match_response(m, user_id))
            
    return user_matches[::-1]

@router.post("/create")
async def create_match(match: MatchCreate, user: dict = Depends(decode_access_token), db: Session = Depends(get_db)):
    match_id = f"m_{uuid.uuid4().hex[:8]}"
    user_id = int(user["sub"])
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
    db.refresh(new_match) # Refresh to get any default values or relationships loaded
    return {"match_id": new_match.id}

def _get_match_players_info(db: Session, match: tables.Match, current_user_id: int):
    """Helper to get active players and check if current user is joined."""
    active_players = []
    is_joined = False

    for p in match.players:
        if p.status == "confirmed":
            user_record = db.query(tables.User).filter(tables.User.id == p.user_id).first()
            username = user_record.display_name if user_record else "Unknown"
            active_players.append(username)

            if p.user_id == current_user_id:
                is_joined = True
    return active_players, is_joined

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

    active_players, is_joined = _get_match_players_info(db, match, user_id)
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
    user_id = int(user["sub"])

    match = db.query(tables.Match).filter(tables.Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    existing_entry = db.query(tables.MatchPlayer).filter(
        tables.MatchPlayer.match_id == match_id,
        tables.MatchPlayer.user_id == user_id
    ).first()

    if existing_entry:
        # Toggle status: confirmed -> left, left -> confirmed
        existing_entry.status = "left" if existing_entry.status == "confirmed" else "confirmed"
    else:
        # Check roster limit before adding new player
        confirmed_players_count = sum(1 for p in match.players if p.status == "confirmed")
        if confirmed_players_count >= match.roster_size:
            raise HTTPException(status_code=400, detail="Match is full")

        new_player = tables.MatchPlayer(match_id=match_id, user_id=user_id, status="confirmed")
        db.add(new_player)

    db.commit()
    db.refresh(match)

    active_players, is_joined = _get_match_players_info(db, match, user_id)

    return {
        "status": "success",
        "current_roster": len(active_players),
        "player_list": active_players,
        "is_joined": is_joined
    }

@router.post("/{match_id}/toggle-cancel")
async def toggle_cancel(match_id: str, user: dict = Depends(decode_access_token), db: Session = Depends(get_db)):
    match = db.query(tables.Match).filter(tables.Match.id == match_id).first()
    user_id = int(user["sub"])
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.host_id != user_id:
        raise HTTPException(status_code=403, detail="Only the host can cancel this match")

    match.is_cancelled = not match.is_cancelled
    db.commit()
    db.refresh(match) # Refresh to ensure the latest state is reflected
    return {"status": "success", "is_cancelled": match.is_cancelled}