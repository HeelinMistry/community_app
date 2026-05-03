"""
SQLAlchemy table definitions.

This module contains the SQLAlchemy model definitions for the application's
database tables, including users, passkeys, matches, and match players.
"""

from sqlalchemy import Column, String, Integer, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base

import uuid

class User(Base):
    """
    Represents the public-facing profile of a user.
    Only contains non-sensitive information.

    Attributes:
        id (str): Unique identifier for the user.
        display_name (str): The user's display name.
        matches_hosted (relationship): Relationship to the matches hosted by the user.
    """
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    display_name = Column(String)
    matches_hosted = relationship("Match", back_populates="host")

class Credential(Base):
    """
    Represents sensitive user credentials and contact information.
    This table is used for authentication and private communication.

    Attributes:
        id (str): Unique identifier for the credentials.
        user_id (str): The user's unique username.

        username (str): The user's unique username.
        hashed_password (str): The hashing to match for login.
    """
    __tablename__ = "credentials"

    id = Column(Integer, primary_key=True, index=True)
    # Link back to the public User profile
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)

    # Sensitive matching/contact fields
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
        date_event (str): The date of the match.
        date_modified (datetime): The last time the match was modified.
        time (str): The time of the match.
        location (str): The location of the match.
        roster_size (int): The maximum number of players for the match.
        cost (str): The cost to participate in the match.
        host_id (str): Foreign key to the user who is hosting the match.
        is_cancelled (bool): Whether the match has been cancelled.
        host (relationship): Relationship to the user hosting the match.
        players (relationship): Relationship to the players participating in the match.
    """
    __tablename__ = "matches"

    id = Column(String, primary_key=True, index=True, default=f"m_{uuid.uuid4().hex[:8]}")
    title = Column(String)
    sport = Column(String)
    duration = Column(String)
    date_event = Column(String)
    date_modified = Column(DateTime, server_default=func.now(), onupdate=func.now())
    time = Column(String)
    location = Column(String)
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
        user_id (str): Foreign key to the user.
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