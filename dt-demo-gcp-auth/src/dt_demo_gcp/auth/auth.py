"""JWT user authentication."""

from time import time
from typing import Literal

import bcrypt
import jose
from fastapi import HTTPException, status
from jose.constants import ALGORITHMS
from jwt_pydantic import JWTPydantic
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from dt_demo_gcp.auth.config import settings

from dt_demo_gcp.auth.models import User


class JWTUser(JWTPydantic):
    """JWT user model."""

    iss: str  # Issuer: dt-demo-gcp
    sub: str  # Subject: the user's ID
    iat: int  # Issued at: UNIX timestamp
    exp: int  # Expiration: UNIX timestamp


class LoginResponse(BaseModel):
    """Login response matching RFC 6749/6750."""

    access_token: str
    token_type: Literal["bearer"] = "bearer"


async def authenticate_user(session: AsyncSession, username: str, password: str) -> LoginResponse:
    """Authenticate user and return JWT token."""
    if settings.jwt_secret_key is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="JWT secret key is not set."
        )

    # Check that the user exists
    user: User | None = (
        await session.execute(select(User).where(User.username == username))
    ).scalar_one_or_none()
    if not user:
        print(f"User '{username}' not found.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid username or password"
        )

    # Check the user's password against the stored hash
    hash = user.hashed_password
    success = bcrypt.checkpw(password.encode("utf-8"), hash)
    if not success:
        print(f"Password for user '{username}' is incorrect, expected hash: {hash}.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid username or password"
        )

    now = int(time())
    exp = now + 60 * 60 * 24  # Token expires in 24 hours

    token = JWTUser.new_token(
        claims={"iss": "dt-demo-gcp", "sub": str(user.id), "iat": now, "exp": exp},
        key=settings.jwt_secret_key,
        algorithm=ALGORITHMS.HS256,
    )
    return LoginResponse(access_token=token)


async def decode_jwt_token(token: str) -> JWTUser:
    """Decode the JWT token and return the user claims.

    The error string, if any, will be included in the HTTP response as an `error` fragment
    in the redirect URL.
    """
    try:
        return JWTUser(token, key=settings.jwt_secret_key)
    except jose.ExpiredSignatureError as e:
        raise ValueError("expired_token") from e
    except jose.JOSEError as e:  # Catch-all for JOSE errors
        raise ValueError("jwt_error") from e
    except Exception as e:
        raise ValueError("unexpected_error") from e
