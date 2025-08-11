# Stage 1: mkdocs build on uv image
# Since we can't run mkdocs directly on the host when using Docker, we use a container
# From https://github.com/astral-sh/uv-docker-example/blob/main/Dockerfile

FROM ghcr.io/astral-sh/uv:debian-slim AS builder

# Install the project into `/app`
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Ensure installed tools can be executed out of the box
ENV UV_TOOL_BIN_DIR=/usr/local/bin

# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

# Build the documentation, by default this will output to /app/site
RUN uv run mkdocs build

########################################################################################

# Stage 2: static file serving
# Use a lightweight web server to serve the static files

FROM joseluisq/static-web-server:2 AS runtime

# Copy the built documentation from the builder stage
COPY --from=builder /app/site /public/dev-docs
