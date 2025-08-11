# Install Minikube and associated tools
########################################

# Minikube -- do not prompt to update as it is a critical component
if command -v minikube &> /dev/null; then
    gum log "✅ Minikube is already installed."
else
    gum log "🛠️  Installing Minikube..."
    if ! (curl -fsSLO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb \
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
    if ! curl -fsSLO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb && sudo apt install ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb; then
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
