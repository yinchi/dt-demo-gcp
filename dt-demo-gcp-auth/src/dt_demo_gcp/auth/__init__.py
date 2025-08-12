"""Authentication module for the DT demo."""

import sys

import pydantic as pyd
from fastapi import FastAPI, cli
from fastapi.responses import PlainTextResponse

from .__version__ import __version__ as version


def plaintext_example(value: str, status_code: int = 200) -> dict[int, dict]:
    """Generate the response schema with `value` as the example for a plaintext response."""
    return {status_code: {"content": {"text/plain": {"example": value}}}}


app = FastAPI()


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


def main():
    """Launch FastAPI dev server.

    Supplies the entrypoint for the `auth` script in pyproject.toml.
    """
    # argv[1:] allows additional arguments to be passed to the FastAPI server.
    sys.argv = f"fastapi dev {__file__}".split() + sys.argv[1:]

    # Launch FastAPI dev server.
    cli.main()
