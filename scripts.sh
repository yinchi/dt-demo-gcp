# Scripts for the project, set up with `source scripts.sh`

# Reload the scripts after any changes
refresh_scripts() {
    pushd $(git rev-parse --show-toplevel) > /dev/null
    source scripts.sh
    popd > /dev/null
}

### SCRIPTS DIRECTORY SETUP ###

# Make all scripts executable
git config alias.chmod '!chmod +x $(git rev-parse --show-toplevel)/scripts/*.sh'

# Run a script in the scripts/ directory
# NOTE: Each script not rely on the current working directory
# Use `git rev-parse --show-toplevel` to get the root of the repository
git config alias.script '!f() { \
    whichscript=$1;
    shift;
    scripts/${whichscript}.sh "$@";
}; f'

### VERSIONING TOOLS SETUP ###

# Run pre-commit hooks (linting, formatting, etc.)
git config alias.precommit '!pre-commit run --all-files'

# Git summary: Summary of the current repo status
git config alias.summary '!git status -sb --ahead-behind'


### DOCKER SETUP ###

# Build the Docker images
bake() {
    # If no arguments, list targets, then fail with exit 1.
    pushd $(git rev-parse --show-toplevel) > /dev/null
    local exitcode
    if [ $# -eq 0 ]; then
        echo "❗️ No bake target specified.  Listing available targets:"
        docker buildx bake --list=targets
        exitcode=1
    else
        docker buildx bake "$@"
        exitcode=$?
    fi
    popd > /dev/null
    return $exitcode
}

# Clean up Docker resources
docker_clean() {
    docker image prune -f --filter "dangling=true"
    docker volume prune --filter "label=com.docker.volume.anonymous"
    docker network prune -f
    docker container prune -f
    docker builder prune -f
}


### FINISH ###
echo "
✅ Shell functions and git aliases set up successfully. You can check your git aliases
with 'git config -l | grep alias.'

Shell functions added:
 - bake()
 - docker_clean()
 - refresh_scripts()
"
