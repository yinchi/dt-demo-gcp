#!/usr/bin/env bash
# Scripts for the project, set up with `./scripts.sh`

# Make all scripts executable
git config alias.chmod '!chmod +x scripts/*.sh'

# Script for setting up a new subproject
git config alias.subproject '!scripts/subproject.sh'

# Run pre-commit hooks (linting, formatting, etc.)
git config alias.precommit '!pre-commit run --all-files'

# Git summary: Summary of the current repo status
git config alias.summary '!git status -sb --ahead-behind'

# Install optional packages
git config alias.install '!scripts/install.sh'

echo "✅ Git aliases set up successfully. You can check them with 'git config -l | grep alias.'"
