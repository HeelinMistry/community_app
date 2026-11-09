import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, Query, status
from sqlalchemy.orm import Session
from app.db import tables
from app.db.database import get_db, SessionLocal
from app.core.security import decode_access_token
from app.websockets.manager import manager

router = APIRouter(prefix="/api/v1/chat", tags=["chat"])

@router.get("")
async def get_chats(
        current_user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    user_id = int(current_user["sub"])

    # 1. Find all product IDs and supplier IDs where:
    #    - The user owns the product/supplier, OR
    #    - There is a message in the room where sender_id == user_id
    owned_products = (
        db.query(tables.Product.id)
        .filter(tables.Product.user_id == user_id)
        .all()
    )
    owned_suppliers = (
        db.query(tables.Supplier.id)
        .filter(tables.Supplier.user_id == user_id)
        .all()
    )

    messaged_rooms = (
        db.query(tables.Message.room_id)
        .filter(tables.Message.sender_id == user_id)
        .distinct()
        .all()
    )

    # Combine all relevant room IDs (product or service IDs) uniquely
    active_room_ids = set(
        [p.id for p in owned_products]
        + [s.id for s in owned_suppliers]
        + [m.room_id for m in messaged_rooms]
    )

    if not active_room_ids:
        return {"user_chats": []}

    user_chats = []

    for room_id in active_room_ids:
        # Fetch the latest message for this room
        latest_message = (
            db.query(tables.Message)
            .filter(tables.Message.room_id == room_id)
            .order_by(tables.Message.timestamp.desc())
            .first()
        )

        if latest_message is None:
            break

        # Optional: fetch details about the product or supplier for context
        item_title = None
        product = (
            db.query(tables.Product)
            .filter(tables.Product.id == room_id)
            .first()
        )
        if product:
            item_title = product.title
        else:
            supplier = (
                db.query(tables.Supplier)
                .filter(tables.Supplier.id == room_id)
                .first()
            )
            if supplier:
                item_title = supplier.business_name

        user_chats.append(
            {
                "room_id": room_id,
                "title": item_title,
                "last_content": latest_message.content if latest_message else None,
                "timestamp": (
                    latest_message.timestamp.replace(tzinfo=timezone.utc).isoformat()
                    if latest_message and latest_message.timestamp
                    else None
                ),
            }
        )

    # Sort chats by latest message timestamp descending (most recent first)
    user_chats.sort(
        key=lambda x: x["timestamp"] if x["timestamp"] else "", reverse=True
    )

    return user_chats

# Helper to decode token from WS query param since headers can be restrictive in iOS URLSession
def get_user_from_ws_token(token: str = Query(...)) -> dict:
    try:
        payload = decode_access_token(token)
        return payload
    except Exception:
        return None


@router.get("/{room_id}/history")
async def get_chat_history(
        room_id: str,
        limit: int = 50,
        current_user: dict = Depends(decode_access_token),
        db: Session = Depends(get_db)
):
    """Fetch paginated chat history for a room."""
    messages = (
        db.query(tables.Message)
        .filter(tables.Message.room_id == room_id)
        .order_by(tables.Message.timestamp.desc())
        .limit(limit)
        .all()
    )

    # Return chronologically
    return [
        {
            "message_id": m.id,
            "sender_id": m.sender_id,
            "content": m.content,
            "timestamp": m.timestamp.replace(tzinfo=timezone.utc)
        }
        for m in messages[::-1]
    ]


@router.websocket("/ws/{room_id}")
async def chat_websocket(
        websocket: WebSocket,
        room_id: str,
        token: str = Query(...)
):
    # Authenticate via token query param
    user_payload = get_user_from_ws_token(token)
    if not user_payload:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    user_id = int(user_payload["sub"])

    await manager.connect(room_id, websocket)

    # Open an independent database session for the socket lifecycle
    db = SessionLocal()
    try:
        while True:
            data = await websocket.receive_json()
            content = data.get("content")
            if not content:
                continue

            # Persist message to SQLite
            msg_id = f"msg_{uuid.uuid4().hex[:8]}"
            timestamp = datetime.now(timezone.utc)

            new_message = tables.Message(
                id=msg_id,
                room_id=room_id,
                sender_id=user_id,
                content=content,
                timestamp=timestamp
            )
            db.add(new_message)
            db.commit()

            # Broadcast structured payload to all connected clients in the room
            outgoing_payload = {
                "message_id": msg_id,
                "sender_id": user_id,
                "content": content,
                "timestamp": timestamp.isoformat()
            }
            await manager.broadcast_to_room(room_id, outgoing_payload)

    except WebSocketDisconnect:
        manager.disconnect(room_id, websocket)
    finally:
        db.close()