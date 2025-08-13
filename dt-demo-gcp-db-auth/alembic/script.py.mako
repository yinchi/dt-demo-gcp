"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
${imports if imports else ""}
# from pydantic_settings import BaseSettings, SettingsConfigDict

# revision identifiers, used by Alembic.
revision: str = ${repr(up_revision)}
down_revision: Union[str, Sequence[str], None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    """Upgrade schema."""
    ${upgrades if upgrades else "pass"}

    # If desired, add bulk inserts here; example as follows:
    # Insert the initial admin user, reading a PydanticSettings value
    # admin_password = bytes(Settings().admin_password, 'utf-8')
    # op.bulk_insert(
    #     user_table,
    #     [
    #         {
    #             'id': str(uuid.uuid4()),  # Generate a unique UUID
    #             'username': 'admin',
    #             'hashed_password': bcrypt.hashpw(admin_password, bcrypt.gensalt()),
    #         }
    #     ]
    # )

def downgrade() -> None:
    """Downgrade schema."""
    ${downgrades if downgrades else "pass"}
