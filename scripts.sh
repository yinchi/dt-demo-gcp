#!/usr/bin/env bash
# Scripts for the project, set up with `./scripts.sh`

# Script for setting up a new subproject
git config alias.subproject '!scripts/subproject.sh'

# Run pre-commit hooks (linting, formatting, etc.)
git config alias.precommit '!pre-commit run --all-files'
