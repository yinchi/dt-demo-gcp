# Install Docker and associated tools
######################################

# Docker Engine -- do not prompt to update as it is a critical component
if command -v docker &> /dev/null; then
    gum log "✅ Docker Engine is already installed."
else
    gum log "🛠️  Installing Docker Engine..."
    if ! sudo apt-get install -yqq \
            docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin; then
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
