from typing import Callable, Dict, List, Optional, Tuple
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        # Maps room_id -> list of (WebSocket, optional user_id)
        self.active_connections: Dict[str, List[Tuple[WebSocket, Optional[int]]]] = {}

    async def connect(
        self, room_id: str, websocket: WebSocket, user_id: Optional[int] = None
    ):
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append((websocket, user_id))

    def disconnect(self, room_id: str, websocket: WebSocket):
        if room_id not in self.active_connections:
            return
        self.active_connections[room_id] = [
            (conn, uid)
            for conn, uid in self.active_connections[room_id]
            if conn is not websocket
        ]
        if not self.active_connections[room_id]:
            del self.active_connections[room_id]

    async def broadcast_to_room_personalized(
        self,
        room_id: str,
        payload_factory: Callable[[Optional[int]], dict],
    ):
        for connection, recipient_user_id in list(self.active_connections.get(room_id, [])):
            try:
                # is_mine is expected to be true if returning to sender
                await connection.send_json(payload_factory(recipient_user_id))
            except Exception:
                self.disconnect(room_id, connection)

    async def broadcast_to_room(self, room_id: str, message: dict):
        for connection, _ in list(self.active_connections.get(room_id, [])):
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect(room_id, connection)


manager = ConnectionManager()