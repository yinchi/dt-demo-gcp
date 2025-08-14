#!/usr/bin/env bash
# Generate environment variables for the auth database (Postgres container)

set -euo pipefail

# cd to this script's directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Check for required commands
for cmd in openssl envsubst gum; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# Check if .env file exists
if [ -f .env ]; then
  gum confirm \
        "❗ The .env file already exists. Do you want to overwrite it?" \
        --default="No"
  if [ "$?" -eq 0 ]; then
    old_env=.env.old.$(date +%Y%m%d%H%M%S)
    cp .env $old_env
    echo "✅ Backed up existing .env to $old_env.  You can use the admin credentials from there"
    echo "   to access the existing database instance, if any."
  else
    echo "❌ Aborting..."
    exit 1
  fi
fi


# Generate random passwords
# 18 bytes -> base64 -> 24-character string
export POSTGRES_PASSWORD=$(openssl rand -base64 18)
export DB_USER=user
export DB_USER_PASSWORD=$(openssl rand -base64 18)

# Set database name and timezone (`ALTER SYSTEM SET timezone` in init.sql)
# This affects the display (but not the storage) behavior of `timestamptz` columns.
export DB_NAME=auth
export DB_TIMEZONE=Europe/London

# Write environment variables to .env file
cat > .env <<EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
DB_USER=$DB_USER
DB_USER_PASSWORD=$DB_USER_PASSWORD
DB_NAME=$DB_NAME
DB_TIMEZONE=$DB_TIMEZONE
EOF

# Set permissions for .env
chmod 600 .env

# Print the path of the .env file
echo "✅ Environment variables generated in .env file: $(git rev-parse --show-toplevel)/db/auth/.env"

# Create the initialization SQL script.  NOTE: ensure secret/ is in `.gitignore`.
# This file will be mounted into /docker-entrypoint-initdb.d/
echo "🛠️ Generating secret/init.sql and setting permissions..."
mkdir -p secret
if ! cat init.sql.template | envsubst > secret/init.sql.tmp; then
    echo "❌ Failed to generate secret/init.sql.tmp"
    exit 1
fi
chmod 600 secret/init.sql.tmp  # Secure the file as it contains plaintext passwords
sudo cp secret/init.sql.tmp secret/init.sql  # Copy to set UID/GID for the Docker container

# Check for `"userns-remap": "default"` in /etc/docker/daemon.json
if [ ! -f /etc/docker/daemon.json ]; then
    echo "❌ /etc/docker/daemon.json not found. Please ensure Docker is installed and configured."
    exit 1
fi
if ! grep -q '"userns-remap": "default"' /etc/docker/daemon.json; then
    uid_base=0
    gid_base=0
else
  # Figure out the correct UID/GID using subuid and subgid
  if ! grep -q "^$(whoami):" /etc/subuid; then
      echo "❌ User $(whoami) is not in /etc/subuid. Add an entry like '$(whoami):100000:65536' to /etc/subuid."
      exit 1
  else
      uid_base=$(grep "^$(whoami):" /etc/subuid | cut -d: -f2)
  fi

  if ! grep -q "^$(whoami):" /etc/subgid; then
      echo "❌ User $(whoami) is not in /etc/subgid. Add an entry like '$(whoami):100000:65536' to /etc/subgid."
      exit 1
  else
      gid_base=$(grep "^$(whoami):" /etc/subgid | cut -d: -f2)
  fi
fi
echo "ℹ️ Calculated uid_base=$uid_base and gid_base=$gid_base.  Adding 999 for postgres..."

# Set ownership and permissions for secret/init.sql
sudo chown $(( uid_base + 999 )):$(( gid_base + 999 )) secret/init.sql  # Docker postgres uid:gid
sudo chmod 600 secret/init.sql
echo "✅ File permissions set for secret/init.sql"

# Unset all variables
unset POSTGRES_PASSWORD DB_USER_PASSWORD DB_USER DB_NAME DB_TIMEZONE

echo "What to do with the existing database container?"
echo "Note: \"down\" options will prompt whether you want to restart \`postgres\`."
db_choice=$(gum choose "down -v" "down" "Keep running")
if [ "$db_choice" == "down" ]; then
    echo "🛑 Stopping and removing the existing db-auth container..."
    if ! docker compose down db-auth; then
      echo "❌ Failed to stop the db-auth container."
      exit 1
  fi
    gum confirm "Restart?" && docker compose up -d db-auth
elif [ "$db_choice" == "down -v" ]; then
    echo "down -v: This will delete all data. Are you sure?"
    gum confirm "Delete volume?" || { echo "❌ Aborted"; exit 1; }
    echo "🛑 Stopping and removing the existing db-auth container and its volumes..."
    if ! docker compose down -v db-auth; then
        echo "❌ Failed to stop the db-auth container."
        exit 1
    fi
    gum confirm "Restart?" && docker compose up -d db-auth
else
    echo "✅ Keeping the existing db-auth container running."
fi

echo "✅ Done!"
