"""Authentication module for the DT demo."""

import sys
from typing import Annotated

import pydantic as pyd
from fastapi import Cookie, Depends, FastAPI, HTTPException, cli, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from fastapi.security.oauth2 import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from typing_extensions import Literal

from dt_demo_gcp.auth.auth import JWTUser, LoginResponse, authenticate_user, decode_jwt_token
from dt_demo_gcp.auth.db import get_session

from .__version__ import __version__ as version


def plaintext_example(value: str, status_code: int = 200) -> dict[int, dict]:
    """Generate the response schema with `value` as the example for a plaintext response."""
    return {status_code: {"content": {"text/plain": {"example": value}}}}


def examples(*tuples: tuple[str, int, Literal["plain", "json"]]) -> dict[int, dict]:
    """Generate the response schema with examples for multiple status codes."""
    return {
        status_code: {"content": {"text/" + _type: {"example": value}}}
        for value, status_code, _type in tuples
    }


app = FastAPI(
    title="DT Demo Authentication Service",
    summary="Authentication service for the DT demo project.",
    version=version,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Message(pyd.BaseModel):
    """Message model.

    Since HTTPException uses `detail` to convey error messages, we use the same field name here.
    """

    detail: str


@app.get("/", summary="Root")
async def root() -> Message:
    """Root endpoint.

    Eventually, we will replace this with a redirect to the platform's home page
    (which will in turn redirect to the login page if the user is not authenticated).
    """
    return Message(detail=f"DT demo authentication service (version {version})")


@app.get(
    "/health",
    summary="Health Check",
    response_class=PlainTextResponse,
    responses=plaintext_example("OK"),
)
async def health() -> str:
    """Health check endpoint."""
    return "OK"


@app.post(
    "/token",
    summary="Token",
    description="""\
Obtain a JWT token for the user. See
[RFC6749 Section 4.1.4](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.4).
Note that we only use the `access_token` and `token_type` fields from the response specification.
""",
    responses=examples(
        ("Invalid username or password", status.HTTP_401_UNAUTHORIZED, "plain"),
    ),
)
async def token(
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    session: AsyncSession = Depends(get_session),
) -> LoginResponse:
    """Obtain a JWT token for the user, or raise 401 Unauthorized.

    Parameters:
        form: The OAuth2 password request form. Contains the username and password.
        session: The database session.  The database contains a "user" table with user IDs (UUIDs),
            usernames, and hashed passwords.
    """
    return await authenticate_user(session, form.username, form.password)


@app.get(
    "/validate",
    summary="Token validation",
    description="""\
Validate the JWT token; for Traefik's ForwardAuth middleware.

If the token is valid, return a 200 OK response.
If the token is missing or invalid, return a HTTP 303 response and redirect to the login page.
Note that HTTP 303 is preferred over HTTP 302 or 307, as it explicitly indicates that the client
should perform a GET request to the provided location.

**TODO**: If the token is valid but the user is not authorized for a specific resource,
return a 403 Forbidden response.
""",
)
async def validate_token(
    session: AsyncSession = Depends(get_session),
    access_token: str | None = Cookie(default=None),
) -> JWTUser:
    """Validate the JWT token."""
    if not access_token:
        raise HTTPException(
            status_code=status.HTTP_303_SEE_OTHER,
            headers={"Location": "/login/?error=missing_token"},
        )
    try:
        claims = await decode_jwt_token(access_token)
        print("Decoded JWT claims: ", claims)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_303_SEE_OTHER,
            headers={"Location": f"/login/?error={str(e)}"},
        ) from e
    return claims


def main():
    """Launch FastAPI dev server.

    Supplies the entrypoint for the `auth` script in pyproject.toml.
    """
    # argv[1:] allows additional arguments to be passed to the FastAPI server.
    sys.argv = f"fastapi dev {__file__}".split() + sys.argv[1:]

    # Launch FastAPI dev server.
    cli.main()
