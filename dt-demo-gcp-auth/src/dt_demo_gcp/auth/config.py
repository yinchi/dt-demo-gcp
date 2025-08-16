"""Configuration settings for the authentication service."""

from dotenv import find_dotenv
from pydantic import PostgresDsn, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Settings for the authentication service."""

    db_user: str
    db_user_password: str
    db_host: str
    db_port: int
    db_name: str

    token_url: str

    # Allow scripts to use this model even if field is not set.
    # Perform check in `dt_demo_gcp.auth.authenticate_user()`
    jwt_secret_key: str | None = None

    @computed_field
    @property
    def database_url(self) -> PostgresDsn:
        """Construct the database URL from the class attributes."""
        return PostgresDsn.build(
            scheme="postgresql+asyncpg",
            username=self.db_user,
            password=self.db_user_password,
            host=self.db_host,
            port=self.db_port,
            path=self.db_name,
        )

    model_config = SettingsConfigDict(
        extra="ignore", env_file=find_dotenv(".env"), env_file_encoding="utf-8"
    )


settings = Settings()
