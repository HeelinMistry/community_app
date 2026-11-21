import uuid
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.db import tables


def get_participant(db: Session, room_id: str, user_id: int) -> Optional[tables.ChatParticipant]:
    return (
        db.query(tables.ChatParticipant)
        .filter(
            tables.ChatParticipant.room_id == room_id,
            tables.ChatParticipant.user_id == user_id,
        )
        .first()
    )


def require_room_participant(db: Session, room_id: str, user_id: int) -> tables.ChatParticipant:
    participant = get_participant(db, room_id, user_id)
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a participant in this chat room",
        )
    return participant


def ensure_participant(
    db: Session, room_id: str, user_id: int, role: str = "member"
) -> tables.ChatParticipant:
    existing = get_participant(db, room_id, user_id)
    if existing:
        return existing
    participant = tables.ChatParticipant(room_id=room_id, user_id=user_id, role=role)
    db.add(participant)
    db.flush()
    return participant


def _resolve_context_owner_and_title(
    db: Session, room_type: tables.RoomType, context_id: str
) -> tuple[Optional[int], str, str]:
    """
    Returns (owner_or_host_user_id, context_title, owner_role).
    Raises 404 if the referenced product, supplier, or match does not exist.
    """
    if room_type == tables.RoomType.PRODUCT:
        product = db.query(tables.Product).filter(tables.Product.id == context_id).first()
        if not product:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        return product.user_id, product.title, "owner"

    if room_type == tables.RoomType.SUPPLIER:
        supplier = db.query(tables.Supplier).filter(tables.Supplier.id == context_id).first()
        if not supplier:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Supplier not found")
        return supplier.user_id, supplier.business_name, "owner"

    if room_type == tables.RoomType.MATCH:
        match = db.query(tables.Match).filter(tables.Match.id == context_id).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
        return match.host_id, match.title, "host"

    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported room type")


def get_or_create_room(
    db: Session,
    room_type: tables.RoomType,
    context_id: str,
    current_user_id: int,
) -> tables.ChatRoom:
    """
    Resolves an existing chat room for (room_type, context_id) and the caller's participation,
    or creates a new one with the appropriate participants.
    """
    owner_id, _, owner_role = _resolve_context_owner_and_title(db, room_type, context_id)

    if room_type in (tables.RoomType.PRODUCT, tables.RoomType.SUPPLIER):
        candidate_rooms = (
            db.query(tables.ChatRoom)
            .filter(
                tables.ChatRoom.room_type == room_type,
                tables.ChatRoom.context_id == context_id,
            )
            .all()
        )

        for room in candidate_rooms:
            participant_ids = {p.user_id for p in room.participants}
            if current_user_id == owner_id and owner_id in participant_ids:
                return room
            if current_user_id in participant_ids and (owner_id is None or owner_id in participant_ids):
                return room

        room = tables.ChatRoom(
            id=f"rm_{uuid.uuid4().hex[:10]}",
            room_type=room_type,
            context_id=context_id,
        )
        db.add(room)
        db.flush()

        if current_user_id == owner_id:
            db.add(tables.ChatParticipant(room_id=room.id, user_id=current_user_id, role=owner_role))
        else:
            db.add(tables.ChatParticipant(room_id=room.id, user_id=current_user_id, role="buyer"))
            if owner_id is not None:
                db.add(tables.ChatParticipant(room_id=room.id, user_id=owner_id, role=owner_role))

        db.commit()
        db.refresh(room)
        return room

    room = (
        db.query(tables.ChatRoom)
        .filter(
            tables.ChatRoom.room_type == tables.RoomType.MATCH,
            tables.ChatRoom.context_id == context_id,
        )
        .first()
    )

    if not room:
        room = tables.ChatRoom(
            id=f"rm_{uuid.uuid4().hex[:10]}",
            room_type=tables.RoomType.MATCH,
            context_id=context_id,
        )
        db.add(room)
        db.flush()
        if owner_id is not None:
            db.add(tables.ChatParticipant(room_id=room.id, user_id=owner_id, role="host"))

    role = "host" if current_user_id == owner_id else "player"
    ensure_participant(db, room.id, current_user_id, role=role)
    db.commit()
    db.refresh(room)
    return room


def resolve_or_create_room_for_target(
    db: Session,
    target_id: str,
    current_user_id: int,
) -> Optional[tables.ChatRoom]:
    """
    Internally resolves a chat room either by existing room ID or by a context ID
    (product, supplier, or match) when a room/history has not yet been established.
    """
    existing_room = db.query(tables.ChatRoom).filter(tables.ChatRoom.id == target_id).first()
    if existing_room:
        return get_or_create_room(
            db=db,
            room_type=existing_room.room_type,
            context_id=existing_room.context_id,
            current_user_id=current_user_id,
        )

    for room_type, model in (
        (tables.RoomType.PRODUCT, tables.Product),
        (tables.RoomType.SUPPLIER, tables.Supplier),
        (tables.RoomType.MATCH, tables.Match),
    ):
        if db.query(model.id).filter(model.id == target_id).first() is not None:
            return get_or_create_room(
                db=db,
                room_type=room_type,
                context_id=target_id,
                current_user_id=current_user_id,
            )

    return None


def get_room_summary(
    db: Session, room: tables.ChatRoom, current_user_id: int
) -> Optional[dict]:
    """
    Builds a privacy-safe chat list item without exposing internal user IDs.
    """
    latest_message = (
        db.query(tables.Message)
        .filter(tables.Message.room_id == room.id)
        .order_by(tables.Message.timestamp.desc())
        .first()
    )

    if latest_message is None:
        return None

    _, context_title, _ = _resolve_context_owner_and_title(db, room.room_type, room.context_id)

    other_participants = [
        p.user.display_name
        for p in room.participants
        if p.user_id != current_user_id and p.user and p.user.display_name
    ]
    peer_name = (
        other_participants[0]
        if len(other_participants) == 1
        else (f"{len(other_participants)} members" if len(other_participants) > 1 else None)
    )

    return {
        "room_id": room.id,
        "room_type": room.room_type.value,
        "context_id": room.context_id,
        "title": context_title,
        "peer_name": peer_name,
        "last_content": latest_message.content,
        "last_message_is_mine": latest_message.sender_id == current_user_id,
        "timestamp": (
            latest_message.timestamp.replace(tzinfo=None).isoformat() + "Z"
            if latest_message.timestamp
            else None
        ),
    }