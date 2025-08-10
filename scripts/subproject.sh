#!/usr/bin/env bash

# This script sets up a new subproject in the current Git repository.
# If `scripts.sh` was run, this script is available via `git subproject`.

set -euo pipefail

echo "Changing directory to the Git repository root..."
cd `git rev-parse --show-toplevel`

echo
echo "=== Subproject setup script ==="

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "gum could not be found, please run 'init.sh' to set up the Git project environment."
    exit 1
fi

# Function to handle Python mkdocs subproject setup
setup_python_mkdocs() {
    echo "What is the name of the Python mkdocs project?"
    project_name=$(gum input --placeholder "Name")
    # Check if the project name is empty
    if [[ -z "$project_name" ]]; then
        echo "❌ No project name provided, aborting."
        exit 1
    fi
    # Check that `./$project_name` does not already exist
    if [[ -d "./$project_name" ]]; then
        echo "❌ Project '$project_name' already exists, aborting."
        exit 1
    fi
    echo "Creating Python project: $project_name"
    uv init --no-package --python 3.13 $project_name

    echo "Setting up mkdocs and dependencies..."
    cd "$project_name"
    uv add mkdocs mkdocs-material mkdocs-open-in-new-tab

    echo "Creating mkdocs project structure..."
    uv run mkdocs new .

    mkdir -p css
    touch css/extra.css

    # Copy mkdocs.yml templates
    echo "Copying mkdocs.yml templates..."
    cp `git rev-parse --show-toplevel`/templates/mkdocs/mkdocs.yml .
    cp `git rev-parse --show-toplevel`/templates/mkdocs/index.md docs/

    echo
    echo "✅ Python mkdocs project '$project_name' created successfully."
    echo "Serve locally with: uv run mkdocs serve"
}

# Function to handle Python app subproject setup
setup_python_app() {
    echo "❌ Create script for 'Python app' not yet implemented"
    exit 1
}

# Function to handle Node.js app subproject setup
setup_nodejs_app() {
    echo "❌Create script for 'Node.js app' not yet implemented"
    exit 1
}

# Use gum to prompt for subproject type
echo "Select the type of subproject to create:"
subproject_type=$(gum choose "Python mkdocs"\
                             "Python app"\
                             "Node.js app")

case $subproject_type in
    "Python mkdocs")
        setup_python_mkdocs
        ;;
    "Python app")
        setup_python_app
        ;;
    "Node.js app")
        setup_nodejs_app
        ;;
    *)
        echo "Invalid subproject type selected."
        exit 1
        ;;
esac
