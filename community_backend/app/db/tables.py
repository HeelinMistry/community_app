"""
SQLAlchemy table definitions.

This module contains the SQLAlchemy model definitions for the application's
database tables, including users, passkeys, matches, and match players.
"""

from sqlalchemy import Column, String, Integer, ForeignKey
from .database import Base

class User(Base):
    """
    Represents a user in the system.

    Attributes:
        id (str): Unique identifier for the user.
        username (str): The user's unique username.
        display_name (str): The user's display name.
    """
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    display_name = Column(String)

class Credential(Base):
    """
    Represents user credential in the system.

    Attributes:
        id (str): Unique identifier for the credentials.
        user_id (str): The user's unique username.
        hashed_password (str): The hashing to match for login.
    """
    __tablename__ = "credentials"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    hashed_password = Column(String)