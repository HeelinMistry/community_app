import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session
from app.core.security import decode_access_token
from app.db import tables
from app.db.database import SessionLocal, get_db
from app.services.chat_rooms import (
    get_participant,
    get_room_summary,
    require_room_participant,
    resolve_or_create_room_for_target,
)
from app.websockets.manager import manager

router = APIRouter(prefix="/api/v1/chat", tags=["chat"])


def _format_message(message: tables.Message, viewer_user_id: int) -> dict:
    ts = message.timestamp
    if ts is not None and ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    elif ts is not None:
        ts = ts.astimezone(timezone.utc)

    return {
        "message_id": message.id,
        "room_id": message.room_id,
        "is_mine": message.sender_id == viewer_user_id,
        "sender_name": message.sender.display_name if message.sender and message.sender.display_name else "Member",
        "content": message.content,
        "timestamp": ts.isoformat() if ts else None,
    }


@router.get("")
async def get_chats(
    current_user: dict = Depends(decode_access_token),
    db: Session = Depends(get_db),
):
    user_id = int(current_user["sub"])

    rooms = (
        db.query(tables.ChatRoom)
        .join(tables.ChatParticipant, tables.ChatParticipant.room_id == tables.ChatRoom.id)
        .filter(tables.ChatParticipant.user_id == user_id)
        .all()
    )

    if not rooms:
        return []

    user_chats = []
    for room in rooms:
        summary = get_room_summary(db=db, room=room, current_user_id=user_id)
        if summary is not None:
            user_chats.append(summary)

    user_chats.sort(key=lambda item: item["timestamp"] or "", reverse=True)
    return user_chats


def _decode_ws_user_id(token: str) -> int | None:
    try:
        payload = decode_access_token(token)
        return int(payload["sub"])
    except Exception:
        return None


@router.get("/{room_id}/history")
async def get_chat_history(
    room_id: str,
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(decode_access_token),
    db: Session = Depends(get_db),
):
    user_id = int(current_user["sub"])

    if not get_participant(db=db, room_id=room_id, user_id=user_id):
        resolved_room = resolve_or_create_room_for_target(
            db=db, target_id=room_id, current_user_id=user_id
        )
        if resolved_room is not None:
            room_id = resolved_room.id

    require_room_participant(db=db, room_id=room_id, user_id=user_id)

    messages = (
        db.query(tables.Message)
        .filter(tables.Message.room_id == room_id)
        .order_by(tables.Message.timestamp.desc())
        .limit(limit)
        .all()
    )

    if not messages:
        return []

    return [_format_message(m, viewer_user_id=user_id) for m in reversed(messages)]


@router.websocket("/{room_id}")
async def chat_websocket(
    websocket: WebSocket,
    room_id: str,
    token: str = Query(...),
):
    user_id = _decode_ws_user_id(token)
    if user_id is None:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    db = SessionLocal()
    try:
        participant = get_participant(db=db, room_id=room_id, user_id=user_id)
        if not participant:
            resolved_room = resolve_or_create_room_for_target(
                db=db, target_id=room_id, current_user_id=user_id
            )
            if resolved_room is not None:
                room_id = resolved_room.id
                participant = get_participant(db=db, room_id=room_id, user_id=user_id)

        if not participant:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        sender = db.query(tables.User).filter(tables.User.id == user_id).first()
        sender_name = sender.display_name if sender and sender.display_name else "Member"

        await manager.connect(room_id, websocket, user_id=user_id)

        while True:
            data = await websocket.receive_json()
            content = (data.get("content") or "").strip()
            if not content:
                continue

            if not get_participant(db=db, room_id=room_id, user_id=user_id):
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                break

            msg_id = f"msg_{uuid.uuid4().hex[:8]}"
            timestamp = datetime.now(timezone.utc)

            new_message = tables.Message(
                id=msg_id,
                room_id=room_id,
                sender_id=user_id,
                content=content,
                timestamp=timestamp,
            )
            db.add(new_message)
            db.commit()

            base_payload = {
                "message_id": msg_id,
                "room_id": room_id,
                "sender_name": sender_name,
                "content": content,
                "timestamp": timestamp.isoformat(),
            }

            await manager.broadcast_to_room_personalized(
                room_id=room_id,
                payload_factory=lambda recipient_user_id: {
                    **base_payload,
                    "is_mine": recipient_user_id == user_id,
                },
            )

    except WebSocketDisconnect:
        manager.disconnect(room_id, websocket)
    finally:
        db.close()