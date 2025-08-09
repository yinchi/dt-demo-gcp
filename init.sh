#!/usr/bin/env bash

# This script initializes the environment for the project.

set -euo pipefail

echo "------------------------------------------------"
echo "0. Checking for prerequisite packages..."
echo "------------------------------------------------"
echo ""

# Check for APT package manager
if ! command -v apt &> /dev/null; then
    echo "⚠️  APT package manager not found. You will need to install certain programs"
    echo "   in this script manually (this script will terminate upon the first missing program)."
else
    echo "✅ APT package manager found."
    echo "Updating package lists..."
    sudo apt-get -yqq update
    echo "✅ Package lists updated."
fi

# Check for `curl` command, and install via APT if not found
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Installing curl..."
    if ! sudo apt-get -yqq install curl; then
        echo "❌ Failed to install curl. Please install it manually."
        exit 1
    else
        echo "✅ curl installed successfully."
    fi
else
    echo "✅ curl already installed."
fi

echo ""
echo "------------------------------------------------"
echo "1. Install gum, used by this script..."
echo "------------------------------------------------"
echo ""

# Check for `gum` command
if ! command -v gum &> /dev/null; then
    # APT package manager
    if command -v apt &> /dev/null; then
        echo "Installing gum using apt..."
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "✅ Charm GPG key added successfully."
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        echo "✅ Charm APT source added successfully."
        sudo apt -yqq update && sudo apt -yqq install gum
        echo "✅ gum installed successfully."
    else
        echo "❌ Unable to install gum. Please install it manually."
        exit 1
    fi
else
    echo "✅ gum already installed."
fi

GUM_SPIN_SPINNER='dot'

echo ""
echo "------------------------------------------------"
echo "2. Checking git setup..."
echo "------------------------------------------------"
echo ""

# Check for `git` command
if ! command -v git &> /dev/null; then
    if ! gum spin --title "Installing git..." -- sudo apt-get -yqq install git; then
        gum log "❌ Failed to install git. Please install it manually."
        exit 1
    else
        gum log "✅ git installed successfully."
    fi
else
    gum log "✅ git already installed."
fi

# Check for `git root` alias
if ! git config --get alias.root &> /dev/null; then
    gum log "❗️ Setting up git alias 'root' to point to the repository root..."
    git config --global alias.root 'rev-parse --show-toplevel'
    gum log "✅ Git alias 'root' set up successfully."
else
    gum log "✅ Git alias 'root' already exists."
fi

# Check if the current directory is a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    gum log "❌ This directory is not a git repository. Please run this script inside a git repository."
    exit 1
fi

# `cd` to the git repository root (we already checked for the `git root` alias)
# Note: script will return to the original directory after execution (if run directly
# instead of sourced)
cd "$(git root)" > /dev/null
gum log "✅ Moving to git repository root at $(git root)..."

# Check git config for `user.name` and `user.email`
if ! git config --get user.name &> /dev/null; then
    gum log "❗️ Git user.name is not set. Please configure it to continue."
    # Prompt user to set user.name here
    echo -n "Please enter your git user.name: "
    read -r user_name
    git config --global user.name "$user_name"
    gum log "✅ Git user.name set to: $user_name"
else
    gum log "✅ Git user.name is set to: $(git config user.name)"
fi

if ! git config --get user.email &> /dev/null; then
    gum log "❗️ Git user.email is not set. Please configure it to continue."
    # Prompt user to set user.email here
    echo -n "Please enter your git user.email: "
    read -r user_email
    git config --global user.email "$user_email"
    gum log "✅ Git user.email set to: $user_email"
else
    gum log "✅ Git user.email is set to: $(git config user.email)"
fi

echo ""
echo "------------------------------------------------"
echo "3. Checking for required programs..."
echo "------------------------------------------------"

# uv, Python package manager
# via developer's install script
if ! command -v uv &> /dev/null; then
    if ! gum spin --title "Installing uv..." -- curl -LsSf https://astral.sh/uv/install.sh | sh; then
        gum log "❌ Failed to install uv. Please install it manually."
        exit 1
    else
        gum log "✅ uv installed successfully."
    fi
else
    gum log "✅ uv already installed."
fi

# Set UV_TOOL_BIN_DIR environment variable in .bashrc if not already set
if [ -z "${UV_TOOL_BIN_DIR:-}" ]; then
    # Set the variable to the default path
    export UV_TOOL_BIN_DIR="$HOME/.local/bin"  # Export to the current shell
    echo "export UV_TOOL_BIN_DIR=\"$UV_TOOL_BIN_DIR\"" >> "$HOME/.bashrc"  # Append to .bashrc
    gum log "Setting UV_TOOL_BIN_DIR to default path: $UV_TOOL_BIN_DIR"
else
    gum log "✅ UV_TOOL_BIN_DIR is already set to: $UV_TOOL_BIN_DIR"
fi

# npm, Node.js package manager
# via apt
if ! command -v npm &> /dev/null; then
    if ! gum spin --title "Installing npm..." -- sudo apt-get -yqq install npm; then
        gum log "❌ Failed to install npm. Please install it manually."
        exit 1
    else
        gum log "✅ npm installed successfully."
    fi
else
    gum log "✅ npm already installed."
fi

# pre-commit, a git hook manager
# via apt
if ! command -v pre-commit &> /dev/null; then
    if ! gum spin --title "Installing pre-commit..." -- sudo apt-get -yqq install pre-commit; then
        gum log "❌ Failed to install pre-commit. Please install it manually."
        exit 1
    else
        gum log "✅ pre-commit installed successfully."
    fi
else
    gum log "✅ pre-commit already installed."
fi
# install pre-commit hooks, checking if the `.pre-commit-config.yaml` file exists
if [ -f .pre-commit-config.yaml ]; then
    if ! gum spin --title "Installing pre-commit hooks..." -- pre-commit install; then
        gum log "❌ Failed to install pre-commit hooks. Please install them manually."
        exit 1
    else
        gum log "✅ pre-commit hooks installed successfully."
    fi
else
    gum log "❗️ .pre-commit-config.yaml file not found. Skipping pre-commit hooks installation."
fi
