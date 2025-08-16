"""Alembic setup."""

import asyncio
from logging.config import fileConfig

from alembic import context
from dotenv import find_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config
from sqlmodel import SQLModel


class Settings(BaseSettings):
    """Settings for the Alembic migrations."""

    db_user_password: str

    model_config = SettingsConfigDict(
        extra="ignore", env_file=find_dotenv(".env"), env_file_encoding="utf-8"
    )


from dt_demo_gcp.auth.models import User  # noqa: E402,F401

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Build the database URL string by interpolating the password
db_user_password = Settings().db_user_password
if not db_user_password:
    raise ValueError("Database user password is not set in the environment.")
url = config.get_main_option("sqlalchemy.url")
url = url.replace("$PASSWORD", db_user_password)

# Update the config with the new URL
# Make sure that `revision_environment = true` is set in alembic.ini
# or commands such as `alembic upgrade` will not be able to access the database
config.set_main_option("sqlalchemy.url", url)

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = SQLModel.metadata

# other values from the config, defined by the needs of env.py,
# can be acquired:
# my_important_option = config.get_main_option("my_important_option")
# ... etc.


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        # compare_server_default=True,  # Enable server_default comparison
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """Run migrations in 'online' mode."""
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        # compare_server_default=True,  # Enable server_default comparison
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """In this scenario we need to create an Engine and associate a connection with the context."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        url=url,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode (async)."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
