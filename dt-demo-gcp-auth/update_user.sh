#!/usr/bin/env bash

# Create or update a user in the database

set -euo pipefail

trap 'unset username hashed new_password new_password_confirm PGPASSWORD DB_USER_PASSWORD' EXIT

echo "Changing directory to the Git repository root..."
cd "$(git rev-parse --show-toplevel)"

# Check for psql
if ! command -v psql &> /dev/null; then
    echo "❌ psql could not be found. Please install PostgreSQL client."
    exit 1
fi

# Check for python3-bcrypt
if ! python3 -c "import bcrypt" &> /dev/null; then
    echo "❌ python3-bcrypt could not be found. Please install it."
    exit 1
fi

# Get list of .env files
env_files=$(find . -name "*.env*" -print)

# Check if any .env files were found
if [ -z "$env_files" ]; then
    echo "❌ No .env files found. Please create one and try again."
    exit 1
fi

# Prompt user to choose a .env file
echo "Please choose a .env file containing your database information:"
select env_file in $env_files; do
    if [ -n "$env_file" ]; then
        echo "You chose: $env_file"
        break
    fi
done

# Load environment variables from the selected .env file
set -a
. "$env_file"
set +a

# Check if required environment variables are set: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_USER_PASSWORD
if [ -z "${DB_HOST:-}" ] || [ -z "${DB_PORT:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ] || [ -z "${DB_USER_PASSWORD:-}" ]; then
    echo "❌ Required environment variables are not set. Please check your .env file."
    echo "   Required variables are: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_USER_PASSWORD"
    exit 1
fi

echo "Testing database connection with found credentials: $DB_USER:***@$DB_HOST:$DB_PORT/$DB_NAME..."

# Check that database is accessible
export PGPASSWORD="$DB_USER_PASSWORD"
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q'; then
    echo "❌ Database $DB_HOST:$DB_PORT/$DB_NAME is not accessible."
    exit 1
else
    echo "✅ Database $DB_HOST:$DB_PORT/$DB_NAME is accessible."
fi

# Prompt for username
read -p "Enter username: " username
echo

# Prompt for new password
read -s -p "Enter new password: " new_password
echo
read -s -p "Confirm new password: " new_password_confirm
echo

if [ "$new_password" != "$new_password_confirm" ]; then
    echo "❌ Passwords do not match."
    exit 1
fi

# Generate random salt using Python's bcrypt.
hashed=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'$new_password', bcrypt.gensalt()).decode())")
if [ -z "$hashed" ]; then
    echo "❌ Failed to generate password hash."
    exit 1
else
    echo "✅ Password hash generated: $hashed"
fi
echo


# Function for new user
new_user() {
    local username=$1
    local hashed=$2
    echo "Creating new user $username..."
    query="INSERT INTO \"user\" (username, hashed_password) VALUES (:'username', :'hashed');"
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -v username="$username" -v hashed="$hashed" \
            <<< "$query"; then
        echo "❌ Failed to insert user into the database."
        exit 1
    else
        echo "✅ User $username created successfully."
    fi
}

# Function for updating user password
update_password() {
    local username=$1
    local hashed=$2
    echo "Updating password for user $username..."
    query="UPDATE \"user\" SET hashed_password = :'hashed' WHERE username = :'username';"
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -v username="$username" -v hashed="$hashed" \
            <<< "$query"; then
        echo "❌ Failed to update user password."
        exit 1
    else
        echo "✅ User $username password updated successfully."
    fi
}

# Check if user already exists
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"  -v user="$username" \
        <<< "SELECT 1 FROM \"user\" WHERE username = :'user';" | grep -q 1; then
    read -p "⚠️ User $username already exists.  Update? (y/n): " update
    if [[ "${update,,}" == "y" || "${update,,}" == "yes" ]]; then
        update_password "$username" "$hashed"
        echo "✅ Updated user $username with new password."
    else
        echo "❌ Aborted."
        exit 1
    fi
else
    new_user "$username" "$hashed"
fi
