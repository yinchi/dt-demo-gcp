"""SQLModel model definitions for the authentication module."""

import copy
from uuid import UUID, uuid4

from pydantic.fields import FieldInfo
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import BYTEA
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.dialects.postgresql import VARCHAR
from sqlmodel import Field, SQLModel

# User ID field
UserIDField: FieldInfo = Field(default_factory=uuid4, sa_column=Column(PG_UUID, primary_key=True))

# User name field
UserNameField: FieldInfo = Field(
    min_length=1, max_length=40, sa_column=Column(VARCHAR, unique=True, nullable=False, index=True)
)
UserNameOptionalField: FieldInfo = copy.deepcopy(UserNameField)
UserNameOptionalField.default = None

# Type for bcrypt hashed passwords
HashField: FieldInfo = Field(sa_column=Column(BYTEA, nullable=False))

# Field for creating new passwords or supplying password inputs to authenticate
# (stored passwords are always hashed)
PlaintextPasswordField: FieldInfo = Field(
    min_length=8, max_length=40, sa_column=Column(VARCHAR, nullable=False)
)
PlaintextPasswordOptionalField: FieldInfo = copy.deepcopy(PlaintextPasswordField)
PlaintextPasswordOptionalField.default = None


class User(SQLModel, table=True):
    """User model for the authentication module.

    Attributes:
        id: Unique identifier for the user.
        username: The user's username.
        hashed_password: The user's hashed password.
    """

    id: UUID = UserIDField
    username: str = UserNameField
    hashed_password: bytes = HashField


class UserCreate(SQLModel):
    """User creation model for the authentication module.

    Used in: POST /users

    Attributes:
        username: The user's username.
        password: The user's password.
    """

    username: str = UserNameField
    password: str = PlaintextPasswordField


class UserUpdate(SQLModel):
    """User update model for the authentication module.

    Used in: PATCH /users/{id}

    Attributes:
        id: Unique identifier for the user.
        password: Input for the user's current password, which we verify against the stored hash.
        new_username: The user's new username, or None to leave unchanged.
        new_password: The user's new password, or None to leave unchanged.
    """

    id: UUID = UserIDField  # Which user to update
    password: str = PlaintextPasswordField  # Current password mandatory
    new_username: str | None = UserNameOptionalField
    new_password: str | None = PlaintextPasswordOptionalField
