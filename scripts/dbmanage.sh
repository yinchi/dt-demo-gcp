#!/usr/bin/env bash

# This script manages Alembic migrations.

set -euo pipefail

echo "Changing directory to the Git repository root..."
cd `git rev-parse --show-toplevel`

echo
echo "=== Show database migration history ==="

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "❌ uv could not be found, please run 'init.sh' to set up the Git project environment."
    exit 1
fi

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "❌ gum could not be found, please run 'init.sh' to set up the Git project environment."
    exit 1
fi

# Find the alembic.ini files
alembic_ini_files=($(find . -name "alembic.ini"))
if [ ${#alembic_ini_files[@]} -eq 0 ]; then
    echo "❌ No alembic.ini files found."
    exit 1
fi

# Prompt user to select a database
echo "Please select a database to show migration history:"
db=$(gum choose "${alembic_ini_files[@]}" --height 10)
echo "Selected database: $db"
echo

path=$(dirname "$db")
package=$(basename "$path")  # Each alembic project corresponds to an `uv` package
cd "$path"

if ! uv run --package "$package" sync  # Ensure uv is in sync for the chosen package
then
    echo "❌ Failed to sync uv for package: $package"
    exit 1
fi

# Show migration history
history() {
    uv run --package "$package" alembic \
        history --indicate-current 2>/dev/null \
        | less -S -+F +0 -#4  # No wrapping, scroll horizontally 4 spaces at a time
}

# Create a new migration
revision() {
    echo "Enter a commit message for the migration:"
    message=$(gum input --prompt "Message:")
    if [ -z "$message" ]; then
        echo "❌ No message provided. Exiting."
        exit 1
    fi
    if ! uv run --package "$package" alembic \
        revision --autogenerate -m "$message" 2>/dev/null; then
        echo "❌ Failed to create migration script."
        exit 1
    else
        echo "✅ Migration script created successfully."
        echo "Please edit the migration script as needed before applying."
    fi
}

# Upgrade the database to the latest migration
upgrade() {
    if ! uv run --package "$package" alembic upgrade head; then
        echo "❌ Failed to upgrade database."
        exit 1
    fi
}

echo "What do you want to do?"
chosen_command=$(gum choose "History" "Revision" "Upgrade" --height 10)
case $chosen_command in
    "History")
        history
        ;;
    "Revision")
        revision
        ;;
    "Upgrade")
        upgrade
        ;;
    *)
        echo "❌ Invalid command."
        exit 1
        ;;
esac
