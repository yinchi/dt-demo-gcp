"""Plotly dash page for login dialog."""

import json
from datetime import date
from sys import argv

import dash
import dash_mantine_components as dmc
import flask
import requests
from dash import Dash, Input, Output, State, dcc, no_update
from dash_compose import composition
from dash_iconify import DashIconify
from fastapi import HTTPException, status
from pydantic import HttpUrl

API_URL = HttpUrl("http://localhost:8000/token")  # The API URL, from within the `auth` container
COPYRIGHT_YEAR = 2025
NDASH = "\u2013"  # en dash
NBSP = "\u00a0"  # non-breaking space

app = Dash(__name__, requests_pathname_prefix="/login/")


def copyright():  # pylint: disable=redefined-builtin
    """Generate the copyright string."""
    # TODO: refactor into a common module for shared frontend components
    year = date.today().year
    return (
        f"© {COPYRIGHT_YEAR}{f'{NDASH}{year}' if year > COPYRIGHT_YEAR else ''} "
        "Anandarup Mukherjee & Yin-Chi Chan, Institute for Manufacturing, "
        "University of Cambridge"
    )


@composition
def layout():
    """App layout using Dash Compose."""
    with dmc.MantineProvider() as ret:
        yield dcc.Location(id="url", refresh=False)
        with dmc.AppShell(
            None,  # Initially no child components, will add as part of composition
            header={"height": 90},
            footer={"height": 40},
            padding="md",
            miw=1200,
        ):
            # TODO: refactor header into a common module for shared frontend components
            with dmc.AppShellHeader(None, miw=1200):
                with dmc.Group(
                    justify="space-between",
                    style={"flex": 1},
                    h="100%",
                    px="md",
                    bg="dark",
                    c="white",
                ):
                    yield dmc.Title("Hospital DT Demo", order=1)
            with dmc.AppShellMain(None, pl="xl", w=1200 - 35):
                with dmc.Stack(None, gap="md"):
                    yield dmc.Title("Login", order=2)
                    yield dmc.Text(
                        "Invalid username or password",
                        id="error-message",
                        c="red",
                        size="lg",
                        display="none",
                    )
                    yield dmc.TextInput(
                        id="username",
                        w="100%",
                        size="lg",
                        label="Username",
                        placeholder="Enter username",
                    )
                    yield dmc.PasswordInput(
                        id="password",
                        w="100%",
                        size="lg",
                        label="Password",
                        placeholder="Enter password",
                    )
                    yield dmc.Button("Login", id="login-button", size="lg")
            # TODO: refactor footer into a common module for shared frontend components
            with dmc.AppShellFooter(None, miw=1200, bg="dark", c="white"):
                with dmc.Group(
                    justify="space-between", style={"flex": 1}, h="100%", px="sm", pt="10", pb="5"
                ):
                    with dmc.Text():
                        yield copyright()
                    with dmc.Anchor(href="https://github.com/yinchi/dt-demo-gcp", target="_blank"):
                        yield DashIconify(icon="ion:logo-github", height=16)
                        yield f"{NBSP}Github"
    return ret


app.layout = layout()


@app.callback(
    Output("error-message", "display"),
    Output("error-message", "children"),
    Output("url", "href"),
    Output("url", "refresh"),
    Input("login-button", "n_clicks"),
    Input("username", "n_submit"),
    Input("password", "n_submit"),
    State("url", "href"),
    State("username", "value"),
    State("password", "value"),
    prevent_initial_call=True,
)
def login(_, _2, _3, current_url: str, username: str, password: str):
    """Check login credentials."""
    # Check inputs
    if not username or not password:
        return "block", "Invalid username or password", no_update, no_update

    # Determine /token API endpoint using current host.  We pass in a `dict` to form
    # data, which the FastAPI backend reads using the
    # fastapi.security.oauth2.OAuth2PasswordRequestForm class.
    request_form = {"grant_type": "password", "username": username, "password": password}
    print("HTTP POST to:", API_URL)

    # Call API endpoint
    try:
        api_response = requests.post(API_URL, data=request_form)
        print("Request body:", api_response.request.body if api_response.request.body else "None")
        print("Response:", api_response.status_code)
        d: dict = api_response.json()
        token = d["access_token"]
    except requests.RequestException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
    print(json.dumps(d, indent=2))

    if api_response.status_code == status.HTTP_200_OK:
        # Parse the response
        try:
            d = api_response.json()
            token = d["access_token"]
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Invalid JSON response"
            )
        except KeyError:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Missing 'access_token' in response",
            )

        # Set the access token in the cookies
        response: flask.Response = dash.callback_context.response
        response.set_cookie(
            key="access_token",
            value=token,
            max_age=24 * 60 * 60,  # 1 day
            httponly=True,
            samesite="Lax",
        )

        return "none", "", no_update, no_update
    if api_response.status_code == status.HTTP_401_UNAUTHORIZED:
        return "block", "Invalid username or password", no_update, no_update
    if api_response.status_code >= status.HTTP_500_INTERNAL_SERVER_ERROR:
        return (
            "block",
            f"Server error occurred ({api_response.status_code}), {api_response.text}",
            no_update,
            no_update,
        )
    return (
        "block",
        f"Unexpected error occurred ({response.status_code}), {response.text}",
        no_update,
        no_update,
    )


if __name__ == "__main__":
    PORT = argv[1] if len(argv) > 1 else 8050
    app.run(port=PORT, debug=True)
