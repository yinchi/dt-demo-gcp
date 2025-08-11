#!/bin/bash
# List files in the scripts/ directory

# Navigate to the root of the git repository
repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Not inside a Git repository." >&2
    exit 1
fi

# Print a header
echo
echo "Listing directory: $repo_root/scripts"

# List all files in the scripts directory
ls -CF "$repo_root/scripts" --color=auto
