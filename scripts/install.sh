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
package=$(gum choose "Docker" "Kubernetes")

# Branch based on selected package
case $package in
    "Docker")
        # Docker Engine -- do not prompt to update as it is a critical component
        if command -v docker &> /dev/null; then
            gum log "✅ Docker Engine is already installed."
        else
            gum log "🛠️  Installing Docker Engine..."
            if ! sudo apt-get install -yqq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                gum log "❌ Failed to install Docker Engine."
                exit 1
            else
                gum log "✅ Docker Engine installed successfully."
            fi
        fi
        # Optional: Lazydocker
        if ! gum confirm "Do you want to install/update Lazydocker?"; then
            gum log " Skipping Lazydocker installation."
        else
            gum log "🛠️  Installing or updating Lazydocker..."
            if ! curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash; then
                gum log "❌ Failed to install Lazydocker."
                exit 1
            else
                gum log "✅ Lazydocker installed successfully."
            fi
        fi
        ;;
    "Kubernetes")
        # Minikube -- do not prompt to update as it is a critical component
        if command -v minikube &> /dev/null; then
            gum log "✅ Minikube is already installed."
        else
            gum log "🛠️  Installing Minikube..."
            if ! (curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb \
                && sudo dpkg -i minikube_latest_amd64.deb \
                && rm minikube_latest_amd64.deb
            ); then
                gum log "❌ Failed to install Minikube."
                exit 1
            else
                gum log "✅ Minikube installed successfully."
            fi
        fi
        # Optional: K9s
        if ! gum confirm "Do you want to install/update K9s?"; then
            gum log "Skipping K9s installation."
        else
            gum log "🛠️  Installing or updating K9s..."
            if ! curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb && sudo apt install ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb; then
                gum log "❌ Failed to install K9s."
                exit 1
            else
                gum log "✅ K9s installed successfully."
            fi
        fi
        # Optional: start minikube cluster
        # TODO: figure out reasonable defaults. For now, default to "No" response.
        if gum confirm "Do you want to start the \"minikube\" cluster?" --default=false; then
            # Check if "minikube" cluster is running.  Note `minikube status -p minikube`
            # returns a non-zero exit code if the cluster does not exist
            if ! minikube -p minikube status -f {{.Host}} | grep -i Running &> /dev/null; then
                gum log "🛠️  Starting minikube cluster..."
                if ! minikube -p minikube start --interactive=true; then
                    gum log "❌ Failed to start minikube cluster."
                    exit 1
                else
                gum log "✅ Minikube cluster started successfully."
                fi
            else
                gum log "❗ Minikube cluster is already running, \`start\` skipped."
            fi
        else
            gum log "Skipping minikube cluster start."
        fi
        ;;
    *)
        gum log "❌ Unknown software set: $package"
        exit 1
        ;;
esac
