#!/usr/bin/env bash

# Recursively find all scripts in the `uv` workspace.
# Wrapper for Python script to set the correct working directory.

set -euo pipefail

echo "Changing directory to the Git repository root..."
cd $(git rev-parse --show-toplevel)

# Check if 'uv' is installed
if ! command -v uv &> /dev/null; then
    echo "❌ 'uv' command not found. Please install it first."
    exit 1
fi

echo
echo "=== UV workspace scripts ==="
uv run scripts/uv_scripts.py "$@"
