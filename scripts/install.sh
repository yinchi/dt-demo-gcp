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

gum log "Select a set to install:"
package=$(gum choose "Docker" "Kubernetes" "Utilities")

# Branch based on selected package
case $package in
    "Docker")
        source ./scripts/install/docker.sh
        ;;
    "Kubernetes")
        source ./scripts/install/k8s.sh
        ;;
    "Utilities")
        source ./scripts/install/utils.sh
        ;;
    *)
        gum log "❌ Unknown software set: $package"
        exit 1
        ;;
esac
