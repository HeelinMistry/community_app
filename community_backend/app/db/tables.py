"""
SQLAlchemy table definitions.

This module contains the SQLAlchemy model definitions for the application's
database tables, including users, passkeys, matches, and match players.
"""

from sqlalchemy import Column, String, Integer, ForeignKey, Boolean, DateTime, Double, REAL, Index, JSON, Text
from sqlalchemy import Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base

import enum
import uuid


class User(Base):
    """
    Represents the public-facing profile of a user.
    Only contains non-sensitive information.

    Attributes:
        id (int): Unique identifier for the user.
        display_name (str): The user's display name.
        matches_hosted (relationship): Relationship to the matches hosted by the user.
        suppliers (relationship): Relationship to the suppliers owned by the user.
        products (relationship): Relationship to the products owned by the user.
    """
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    display_name = Column(String)
    matches_hosted = relationship("Match", back_populates="host")
    suppliers = relationship("Supplier", back_populates="owner")
    products = relationship("Product", back_populates="owner")


class Credential(Base):
    """
    Represents sensitive user credentials and contact information.
    This table is used for authentication and private communication.

    Attributes:
        id (int): Unique identifier for the credentials.
        user_id (int): Foreign key to the user profile.
        username (str): The user's unique username.
        email (str): The user's unique email address.
        cell_number (str): The user's cell number.
        hashed_password (str): The hashed password for login.
    """
    __tablename__ = "credentials"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)

    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    cell_number = Column(String)
    hashed_password = Column(String)


class Match(Base):
    """
    Represents a sports match hosted by a user.

    Attributes:
        id (str): Unique identifier for the match.
        title (str): The title of the match.
        sport (str): The sport being played.
        duration (str): The duration of the match.
        start_datetime (datetime): The datetime of the match.
        date_modified (datetime): The last time the match was modified.
        location (str): The location of the match.
        latitude (float): The latitude of the match.
        longitude (float): The longitude of the match.
        roster_size (int): The maximum number of players for the match.
        cost (str): The cost to participate in the match.
        host_id (int): Foreign key to the user who is hosting the match.
        is_cancelled (bool): Whether the match has been cancelled.
        host (relationship): Relationship to the user hosting the match.
        players (relationship): Relationship to the players participating in the match.
    """
    __tablename__ = "matches"

    id = Column(String, primary_key=True, index=True, default=lambda: f"m_{uuid.uuid4().hex[:8]}")
    title = Column(String)
    sport = Column(String)
    duration = Column(String)
    start_datetime = Column(DateTime)
    date_modified = Column(DateTime, server_default=func.now(), onupdate=func.now())
    location = Column(String)
    latitude = Column(Double)
    longitude = Column(Double)
    roster_size = Column(Integer, default=0)
    cost = Column(String)
    host_id = Column(Integer, ForeignKey("users.id"))
    is_cancelled = Column(Boolean, default=False)

    host = relationship("User", back_populates="matches_hosted")
    players = relationship("MatchPlayer", back_populates="match", cascade="all, delete-orphan")


class MatchPlayer(Base):
    """
    Represents a player participating in a match.

    Attributes:
        id (int): Unique identifier for the match player entry.
        match_id (str): Foreign key to the match.
        user_id (int): Foreign key to the user.
        status (str): The status of the player (e.g., 'confirmed', 'pending').
        date_modified (datetime): The last time the entry was modified.
        match (relationship): Relationship to the match.
    """
    __tablename__ = "match_players"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    match_id = Column(String, ForeignKey("matches.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String, default="confirmed")
    date_modified = Column(DateTime, server_default=func.now(), onupdate=func.now())

    match = relationship("Match", back_populates="players")


class Supplier(Base):
    """
    Represents a supplier of services or products.

    Attributes:
        id (str): Unique identifier for the supplier.
        user_id (int): Foreign key to the user who owns this supplier entry.
        business_name (str): The name of the business.
        description (str): A description of the services or products offered.
        latitude (float): The latitude of the supplier's location.
        longitude (float): The longitude of the supplier's location.
        service_radius (float): The radius of the service area in kilometers.
        category (str): The category of the supplier.
        owner (relationship): Relationship to the user who owns this supplier entry.
    """
    __tablename__ = "suppliers"

    id = Column(String, primary_key=True, default=lambda: f"s_{uuid.uuid4().hex[:8]}")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    business_name = Column(String, nullable=False)
    description = Column(String)
    latitude = Column(REAL, nullable=False)
    longitude = Column(REAL, nullable=False)
    service_radius = Column(REAL)
    category = Column(String)

    owner = relationship("User", back_populates="suppliers")

    __table_args__ = (
        Index("idx_supplier_location", "latitude", "longitude"),
    )


class Product(Base):
    """
    Represents an informal product listing created by a user.

    Attributes:
        id (str): Unique identifier for the product.
        user_id (int): Foreign key to the user who owns this product listing.
        title (str): The title of the product.
        description (str): A detailed description of the product.
        product_type (str): The type of product listing (defaults to 'advertising').
        tags (list or JSON): Stored tags associated with the product.
        latitude (float): The latitude of the product's location.
        longitude (float): The longitude of the product's location.
        service_radius (float): The delivery or pickup radius in meters/kilometers.
        is_available (bool): Whether the product is currently available.
        owner (relationship): Relationship to the user who owns this product entry.
        images (relationship): Relationship to associated product images.
        reviews (relationship): Relationship to reviews for this product.
    """
    __tablename__ = "products"

    id = Column(String, primary_key=True, default=lambda: f"p_{uuid.uuid4().hex[:8]}")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(String)
    product_type = Column(String, default="advertising", nullable=False)
    tags = Column(JSON)
    latitude = Column(REAL, nullable=False)
    longitude = Column(REAL, nullable=False)
    service_radius = Column(REAL, nullable=False)
    is_available = Column(Boolean, default=True)

    owner = relationship("User", back_populates="products")
    images = relationship("Images", back_populates="product", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="product", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_product_location", "latitude", "longitude"),
    )


class Images(Base):
    __tablename__ = "images"

    id = Column(String, primary_key=True, default=lambda: f"img_{uuid.uuid4().hex[:8]}")
    product_id = Column(String, ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    image_url = Column(String, nullable=False)

    product = relationship("Product", back_populates="images")


class ReviewState(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"


class Review(Base):
    """
    Represents a customer's proof-of-service review/vouch for a product.

    Attributes:
        id (str): Unique identifier for the review.
        product_id (str): Foreign key to the product being reviewed.
        user_id (int): Foreign key to the customer who submitted the proof-of-service.
        rating (int): Binary sentiment rating (-1 for negative/issue, +1 for positive vouch).
        comment (str): Optional text feedback or note.
        latitude (float): Latitude where the review/proof was submitted.
        longitude (float): Longitude where the review/proof was submitted.
        state (ReviewState): Moderation/verification state of the review.
        created_at (DateTime): Timestamp when the review was submitted.
    """
    __tablename__ = "reviews"

    id = Column(String, primary_key=True, default=lambda: f"rv_{uuid.uuid4().hex[:8]}")
    product_id = Column(String, ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    rating = Column(Integer, nullable=False)
    comment = Column(String, nullable=True)
    latitude = Column(REAL, nullable=False)
    longitude = Column(REAL, nullable=False)

    state = Column(
        SQLEnum(ReviewState),
        nullable=False,
        default=ReviewState.PENDING,
        server_default=ReviewState.PENDING.value,
    )

    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    product = relationship("Product", back_populates="reviews")
    owner = relationship("User")


class RoomType(str, enum.Enum):
    PRODUCT = "product"
    SUPPLIER = "supplier"
    MATCH = "match"


class ChatRoom(Base):
    """
    Represents a dedicated chat room decoupled from product, supplier, or match IDs.
    """
    __tablename__ = "chat_rooms"

    id = Column(String, primary_key=True, default=lambda: f"rm_{uuid.uuid4().hex[:10]}")
    room_type = Column(SQLEnum(RoomType), nullable=False, index=True)
    context_id = Column(String, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    participants = relationship(
        "ChatParticipant", back_populates="room", cascade="all, delete-orphan"
    )
    messages = relationship(
        "Message", back_populates="room", cascade="all, delete-orphan"
    )

    __table_args__ = (
        Index("idx_chat_room_type_context", "room_type", "context_id"),
    )


class ChatParticipant(Base):
    """
    Tracks which users belong to a chat room and their role in that context.
    """
    __tablename__ = "chat_participants"

    id = Column(Integer, primary_key=True, autoincrement=True)
    room_id = Column(
        String, ForeignKey("chat_rooms.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    role = Column(String, default="member", nullable=False)
    joined_at = Column(DateTime, server_default=func.now(), nullable=False)

    room = relationship("ChatRoom", back_populates="participants")
    user = relationship("User")

    __table_args__ = (
        Index("uq_chat_participant_room_user", "room_id", "user_id", unique=True),
    )


class Message(Base):
    """
    Represents messages sent inside a chat room.
    """
    __tablename__ = "messages"

    id = Column(String, primary_key=True)
    room_id = Column(
        String, ForeignKey("chat_rooms.id", ondelete="CASCADE"), index=True, nullable=False
    )
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=func.now(), index=True)

    room = relationship("ChatRoom", back_populates="messages")
    sender = relationship("User")