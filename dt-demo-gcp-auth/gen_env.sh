#!/usr/bin/env bash
# Generate environment variables for the auth database (Postgres container)
# See: https://docs.pydantic.dev/latest/concepts/pydantic_settings/#field-value-priority

set -euo pipefail

# cd to this script's directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Check for existing .env file and prompt to overwrite
if [ -f ".env" ]; then
    read -p "⚠️  .env file already exists. Overwrite? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "❌ Aborted."
        exit 1
    fi
fi

# Check for required commands
for cmd in openssl envsubst gum; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

SOURCE_ENV_FILE="../dt-demo-gcp-db-auth/.env"

# Check for $SOURCE_ENV_FILE
if [ ! -f "$SOURCE_ENV_FILE" ]; then
    echo "❌ $SOURCE_ENV_FILE file not found. Please create it and try again."
    exit 1
fi

# Get DB_NAME from $SOURCE_ENV_FILE
DB_NAME=$(grep -oP '(?<=^DB_NAME=).*' "$SOURCE_ENV_FILE")
if [ -z "$DB_NAME" ]; then
    echo "❌ DB_NAME not found in $SOURCE_ENV_FILE. Please set it and try again."
    exit 1
fi

# Get DB_USER from $SOURCE_ENV_FILE
DB_USER=$(grep -oP '(?<=^DB_USER=).*' "$SOURCE_ENV_FILE")
if [ -z "$DB_USER" ]; then
    echo "❌ DB_USER not found in $SOURCE_ENV_FILE. Please set it and try again."
    exit 1
fi

# Get DB_USER_PASSWORD from $SOURCE_ENV_FILE
DB_USER_PASSWORD=$(grep -oP '(?<=^DB_USER_PASSWORD=).*' "$SOURCE_ENV_FILE")
if [ -z "$DB_USER_PASSWORD" ]; then
    echo "❌ DB_USER_PASSWORD not found in $SOURCE_ENV_FILE. Please set it and try again."
    exit 1
fi

echo "✅ Environment variables read from $SOURCE_ENV_FILE"

# Generate JWT_SECRET_KEY
# This will invalidate all existing user sessions, which is good since we are
# updating the server settings.
JWT_SECRET_KEY=$(openssl rand -base64 48)

echo "✅ Generated JWT_SECRET_KEY."

# Write the new environment variables to a .env file
cat <<EOF > .env
DB_HOST=localhost
DB_PORT=30001
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_USER_PASSWORD=$DB_USER_PASSWORD

JWT_SECRET_KEY=$JWT_SECRET_KEY
EOF

echo "✅ Environment variables written to .env file."
