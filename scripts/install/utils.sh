# Install utilities

# Invoke via `git install` (runs `../install.sh`), then choose "Utilities"
# Note: install.sh has `set -euo pipefail`, so we can stop installation if any command fails

###########################################################################

# Scripts, for apps not available via apt/snap

install_lazydocker() {
    echo
    echo "🛠️   Fetching lazydocker..."
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    echo "🛠️   Installing lazydocker..."
    echo "✅ lazydocker installation complete!"
}

###########################################################################

# Create a named pipe from a here string

program_list=$(mktemp /tmp/program_list.XXXXXX)

cat <<"EOF" > $program_list
fx: Terminal JSON viewer (snap)
jq: Command-line JSON processor (apt)
ranger: Console file manager (apt)
lazydocker: Docker GUI (script)
pgcli: Postgres CLI (apt)
EOF

# gum choose, with each line of the program list as an option
# read the file and wrap each line in quotes

# generate a temporary filename randomly
selected_programs=$(mktemp /tmp/selected_programs.XXXXXX)

# echo $selected_programs

echo
echo "What do you want to install?"
gum choose --no-limit --selected=* \
  --header "X to toggle, enter to confirm" \
  < $program_list | sort | sed 's/^/"/; s/$/"/' > $selected_programs

# Each line is quoted, remove the quotes
sed -i 's/^"\(.*\)"$/\1/' $selected_programs

echo

# APT
#####

# Collect apt packages (marked with `(apt)`), taking the name before the colon
apt_selection=$(grep ' (apt)$' $selected_programs | cut -d: -f1)

if [[ -n "$apt_selection" ]]; then
    echo "🛠️   Installing apt packages: $apt_selection"
    sudo apt install -yqq $apt_selection
fi
echo "✅ Apt installation complete!"
echo

# SNAP
######

# Collect snap packages (marked with `(snap)`), taking the name before the colon
snap_selection=$(grep ' (snap)$' $selected_programs | cut -d: -f1)

if [[ -n "$snap_selection" ]]; then

    # Ensure snap is installed.  Snap is installed by default on Ubuntu, but may have been
    # removed or the user is using a different Linux distribution.
    # Note we still only support apt-based systems (e.g. Ubuntu, Debian).
    if ! command -v snap &> /dev/null; then
        install_snap=$(gum confirm "snap could not be found, install snap?")
        if [ "$install_snap" = true ]; then
            sudo apt install -y snapd
        else
            echo "❌ Snap installation aborted."
            exit 1
        fi
    fi

    echo "🛠️   Installing snap packages: $snap_selection"
    sudo snap install $snap_selection
fi
echo "✅ Snap installation complete!"
echo

# SCRIPTS
#########

# Collect script packages (marked with `(script)`), taking the name before the colon
script_selection=$(grep ' (script)$' $selected_programs | cut -d: -f1)

if [[ -n "$script_selection" ]]; then
    echo "🛠️   Installing script packages..."
    # Install each script package
    for pkg in $script_selection; do
        install_$pkg
    done
fi

rm $selected_programs $program_list

echo "✅ Install script complete!"
