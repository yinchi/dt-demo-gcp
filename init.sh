#!/usr/bin/env bash

# This script initializes the environment for the project.

set -euo pipefail

# Check whether $XDG_DATA_HOME is unset, set to the default value, or set to a non-default value
# See related VS Code issue: https://github.com/microsoft/vscode/issues/237608
if [ "${XDG_DATA_HOME:-}" == "$HOME/.local/share" ]; then
    echo "✅ XDG_DATA_HOME is set to the default value: $HOME/.local/share."
elif [ -z "${XDG_DATA_HOME:-}" ]; then
    echo "✅ XDG_DATA_HOME is unset, thus using the default value: $HOME/.local/share."
else
    echo "❌ XDG_DATA_HOME is set to '$XDG_DATA_HOME' and not equal to $HOME/.local/share."
    echo "   This often happens when running the script in a VS Code terminal installed via Snap."
    echo "   Consider reinstalling VS Code via your package manager (e.g., apt)."
    echo "   Also, make sure to unset XDG_DATA_HOME if it is set manually."
    exit 1
fi

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
    echo "🛠️ curl is not installed. Installing curl..."
    if ! sudo apt-get -yqq install curl; then
        echo "❌ Failed to install curl. Please install it manually."
        exit 1
    else
        echo "✅ curl installed successfully."
    fi
else
    echo "✅ curl already installed."
fi

# Check for `python3-ipykernel`, used to run Python notebooks (if no venv)
if ! python3 -c "import ipykernel" &> /dev/null; then
    echo "🛠️ python3-ipykernel is not installed. Installing python3-ipykernel..."
    if ! sudo apt-get -yqq install python3-ipykernel; then
        echo "❌ Failed to install python3-ipykernel. Please install it manually."
        exit 1
    else
        echo "✅ python3-ipykernel installed successfully."
    fi
else
    echo "✅ python3-ipykernel already installed."
fi

# Check for `python3-nbformat`
if ! python3 -c "import nbformat" &> /dev/null; then
    echo "🛠️ python3-nbformat is not installed. Installing python3-nbformat..."
    if ! sudo apt-get -yqq install python3-nbformat; then
        echo "❌ Failed to install python3-nbformat. Please install it manually."
        exit 1
    else
        echo "✅ python3-nbformat installed successfully."
    fi
else
    echo "✅ python3-nbformat already installed."
fi

# Check for `python3-nbclient`
if ! python3 -c "import nbclient" &> /dev/null; then
    echo "🛠️ python3-nbclient is not installed. Installing python3-nbclient..."
    if ! sudo apt-get -yqq install python3-nbclient; then
        echo "❌ Failed to install python3-nbclient. Please install it manually."
        exit 1
    else
        echo "✅ python3-nbclient installed successfully."
    fi
else
    echo "✅ python3-nbclient already installed."
fi

# Check for `python3-git`, used to stamp Python notebooks with git information (if no venv)
if ! python3 -c "import git" &> /dev/null; then
    echo "🛠️ python3-git is not installed. Installing python3-git..."
    if ! sudo apt-get -yqq install python3-git; then
        echo "❌ Failed to install python3-git. Please install it manually."
        exit 1
    else
        echo "✅ python3-git installed successfully."
    fi
else
    echo "✅ python3-git already installed."
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
        echo "🛠️ Installing gum using apt..."
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
    gum log "🛠️ Setting up git alias 'root' to point to the repository root..."
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
gum log "🛠️ Moving to git repository root at $(git root)..."

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
