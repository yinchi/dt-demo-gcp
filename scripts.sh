# Scripts for the project, set up with `source scripts.sh`

# Reload the scripts after any changes
refresh_scripts() {
    pushd `git rev-parse --show-toplevel` > /dev/null
    source scripts.sh
    popd > /dev/null
}

### SCRIPTS DIRECTORY SETUP ###

# Make all scripts executable
git config alias.chmod '!chmod +x scripts/*.sh'

# Script for setting up a new subproject
git config alias.subproject '!scripts/subproject.sh'

# Install optional packages
git config alias.install '!scripts/install.sh'


### VERSIONING TOOLS SETUP ###

# Run pre-commit hooks (linting, formatting, etc.)
git config alias.precommit '!pre-commit run --all-files'

# Git summary: Summary of the current repo status
git config alias.summary '!git status -sb --ahead-behind'


### FINISH ###
echo "✅ Git aliases set up successfully. You can check them with 'git config -l | grep alias.'"
