#!/usr/bin/env bash

# This script sets up a new subproject in the current Git repository.
# If `scripts.sh` was run, this script is available via `git subproject`.

set -euo pipefail

echo "Changing directory to the Git repository root..."
cd `git rev-parse --show-toplevel`

echo
echo "=== Install optional packages ==="

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "gum could not be found, please run 'init.sh' to set up the Git project environment."
    exit 1
fi

gum log "Select a package to install:"
package=$(gum choose "quarto")

# Branch based on selected package
case $package in
    "quarto")
        gum log "🛠️ Installing quarto..."
        if ! (curl -fsSL https://quarto.org/download/latest/quarto-linux-amd64.deb -o quarto.deb && \
              sudo dpkg -i quarto.deb && \
              rm quarto.deb); then
            gum log "❌ Failed to install quarto. Please check your internet connection or permissions."
            exit 1
        fi
        gum log "✅ quarto installed successfully."
        ;;
    *)
        gum log "❌ Unknown package: $package"
        exit 1
        ;;
esac
