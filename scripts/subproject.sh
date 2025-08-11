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
    uv init --no-package --python 3.13 --no-workspace $project_name

    echo "Setting up mkdocs and dependencies..."
    cd "$project_name"
    uv add mkdocs mkdocs-material mkdocs-open-in-new-tab

    echo "Creating mkdocs project structure..."
    uv run mkdocs new .
    rm -f main.py  # Remove the default main.py file

    # Copy mkdocs.yml templates
    echo "Copying mkdocs.yml templates..."
    cp -r `git rev-parse --show-toplevel`/templates/mkdocs/* .

    echo
    echo "✅ Python mkdocs project '$project_name' created successfully."
    echo "Serve locally with: uv run mkdocs serve"
}

# Function to handle Python project setup
setup_python_project() {
    echo "What is the name of the Python project?"
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

    # --app, --package, or both?
    echo "Select the type of Python project to create:"
    app_type=$(gum choose "App" "Library")
    app_flags=()
    if [[ "$app_type" == "App" ]]; then
        app_flags+=(--app --package)
    elif [[ "$app_type" == "Library" ]]; then
        app_flags+=(--lib)
    fi

    # Create the project. Note uv will automatically search for a workspace in a parent directory.
    echo "Creating Python project: $project_name"
    if ! uv init "${app_flags[@]}" "$project_name"; then
        echo "❌ Failed to create Python project: $project_name"
        exit 1
    fi

    # Search src/* and remove py.typed if found; `--lib` adds this but we won't use it
    # (We can use type hints but won't enforce them)
    # Use `find` as we don't know the exact location (e.g. foo-bar may become foo_bar)
    find "$project_name/src/" -name "py.typed" -exec rm -f {} +

    # Run uv sync to add the project to the workspace's virtual environment
    uv sync --package "$project_name"
}

# Function to handle Node.js project setup
setup_nodejs_project() {
    echo "❌Create script for 'Node.js project' not yet implemented"
    exit 1
}

# Use gum to prompt for subproject type
echo "Select the type of subproject to create:"
subproject_type=$(gum choose "Python mkdocs"\
                             "Python project"\
                             "Node.js project")

case $subproject_type in
    "Python mkdocs")
        setup_python_mkdocs
        ;;
    "Python project")
        setup_python_project
        ;;
    "Node.js project")
        setup_nodejs_project
        ;;
    *)
        echo "Invalid subproject type selected."
        exit 1
        ;;
esac
