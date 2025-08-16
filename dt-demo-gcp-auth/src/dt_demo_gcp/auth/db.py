"""Database session management."""

from typing import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from dt_demo_gcp.auth.config import settings

engine = create_async_engine(str(settings.database_url))
async_session_maker = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_session() -> AsyncIterator[AsyncSession]:
    """Get a database session."""
    async with async_session_maker() as session:
        yield session
