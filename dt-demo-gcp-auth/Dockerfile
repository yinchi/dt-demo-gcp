# An example using multi-stage image builds to create a final image without uv.
# Copied from: https://github.com/astral-sh/uv-docker-example/blob/main/multistage.Dockerfile

# First, build the application in the `/app` directory.
# See `Dockerfile` for details.
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Disable Python downloads, because we want to use the system interpreter
# across both images. If using a managed Python version, it needs to be
# copied from the build image into the final image; see `standalone.Dockerfile`
# for an example.
ENV UV_PYTHON_DOWNLOADS=0

# Copy only the project definition files.  This allows us to cache the dependencies,
# while changes to the application code will not invalidate the cache.
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=dt-demo-gcp-auth/pyproject.toml,target=dt-demo-gcp-auth/pyproject.toml \
    --mount=type=bind,source=dt-demo-gcp-auth/README.md,target=dt-demo-gcp-auth/README.md \
    --mount=type=bind,source=dt-demo-gcp-auth/src/dt_demo_gcp/auth/__version__.py,target=dt-demo-gcp-auth/src/dt_demo_gcp/auth/__version__.py \
    uv sync --no-install-project --package dt-demo-gcp-auth --frozen --no-dev

# Copy over the full workspace projects, including code, and install them to the virtual environment
COPY pyproject.toml README.md uv.lock /app/
COPY dt-demo-gcp-auth /app/dt-demo-gcp-auth
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --package dt-demo-gcp-auth --frozen --no-dev

# Then, use a final image without uv
FROM python:3.13-slim-bookworm
# It is important to use the image that matches the builder, as the path to the
# Python executable must be the same, e.g., using `python:3.11-slim-bookworm`
# will fail.

# Copy the application from the builder
COPY --from=builder --chown=app:app /app /app

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Run the FastAPI application by default
ENTRYPOINT [ "fastapi", "dev", "--host", "0.0.0.0", "--port", "8000", "--no-reload", \
    "/app/dt-demo-gcp-auth/src/dt_demo_gcp/auth/"]

EXPOSE 8000
