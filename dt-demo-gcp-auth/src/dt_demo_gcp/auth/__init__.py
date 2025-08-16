"""Authentication module for the DT demo."""

import sys
from typing import Annotated

import pydantic as pyd
from fastapi import Depends, FastAPI, cli, status
from fastapi.middleware.wsgi import WSGIMiddleware
from fastapi.responses import PlainTextResponse
from fastapi.security.oauth2 import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from typing_extensions import Literal

from dt_demo_gcp.auth.auth import LoginResponse, authenticate_user
from dt_demo_gcp.auth.dash_login import app as login_app
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

app.mount("/login", WSGIMiddleware(login_app.server))  # Mount the Dash app at /login


class Message(pyd.BaseModel):
    """Message model.

    Since HTTPException uses `detail` to convey error messages, we use the same field name here.
    """

    detail: str


@app.get("/", summary="Root")
async def root() -> Message:
    """Root endpoint."""
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


EXAMPLE_TOKEN_RESPONSE = LoginResponse(access_token="string").model_dump(
    mode="json", exclude_none=True
)


@app.post(
    "/token",
    summary="Token",
    responses=examples(
        ("Invalid username or password", status.HTTP_401_UNAUTHORIZED, "plain"),
    ),
)
async def token(
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    session: AsyncSession = Depends(get_session),
) -> LoginResponse:
    """Token endpoint."""
    return await authenticate_user(session, form.username, form.password)


def main():
    """Launch FastAPI dev server.

    Supplies the entrypoint for the `auth` script in pyproject.toml.
    """
    # argv[1:] allows additional arguments to be passed to the FastAPI server.
    sys.argv = f"fastapi dev {__file__}".split() + sys.argv[1:]

    # Launch FastAPI dev server.
    cli.main()
