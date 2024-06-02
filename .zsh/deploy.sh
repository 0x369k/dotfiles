#!/bin/bash

# Define colors and symbols for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK="${GREEN}✔${NC}"
WARN="${YELLOW}⚠${NC}"
ERROR="${RED}✖${NC}"
INFO="${BLUE}ℹ${NC}"

# Define directories and variables
DOTFILES_DIR="$HOME/.dotfiles"
GIT_DIR="$DOTFILES_DIR"
REPO_URL="https://github.com/0x369k/dotfiles.git"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="$HOME/.dotfiles_backup_$TIMESTAMP"

# Log and error functions
log_error() {
    echo -e "${ERROR} $1" >&2
    exit 1
}

info() {
    echo -e "${INFO} $1"
}

warn() {
    echo -e "${WARN} $1"
}

success() {
    echo -e "${CHECK} $1"
}

# Check for necessary dependencies
check_dependencies() {
    command -v git >/dev/null 2>&1 || log_error "Git is not installed. Please install Git and try again."
    if [[ $1 == "--docker" ]]; then
        command -v docker >/dev/null 2>&1 || log_error "Docker is not installed. Please install Docker and try again."
        command -v docker-compose >/dev/null 2>&1 || log_error "Docker Compose is not installed. Please install Docker Compose and try again."
    fi
}

# Backup existing dotfiles
backup_dotfiles() {
    dotfiles=$(git --git-dir="$GIT_DIR" --work-tree="$HOME" ls-tree -r HEAD --name-only)
    backup_needed=false

    for file in $dotfiles; do
        if [ -e "$HOME/$file" ]; then
            warn "$file will be replaced and backed up to $BACKUP_DIR/$file"
            backup_needed=true
        fi
    done

    if [ "$backup_needed" = true ]; then
        read -p "Do you want to continue and back up these files? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Operation aborted"
        fi

        info "Backing up existing dotfiles to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR" || log_error "Could not create backup directory"

        for file in $dotfiles; do
            if [ -e "$HOME/$file" ]; then
                mkdir -p "$BACKUP_DIR/$(dirname "$file")"
                mv "$HOME/$file" "$BACKUP_DIR/$file" || log_error "Could not back up $file"
                success "$file backed up to $BACKUP_DIR/$file"
            fi
        done
    else
        info "No files to back up."
    fi
}

# Initialize Git repository
initialize_repo() {
    if [ ! -d "$GIT_DIR/HEAD" ]; then
        info "Initializing Git repository"
        git --git-dir="$GIT_DIR" init --bare || log_error "Could not initialize Git repository"
    else
        info "Git repository already exists"
        if [ "$FORCE_OVERWRITE" = true ]; then
            info "Forcing overwrite of existing repository"
        else
            warn "Git repository already exists. Do you want to proceed and overwrite the existing configuration?"
            read -p "Confirm with [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_error "Operation aborted"
            fi
        fi
    fi
}

# Setup Docker container
setup_docker_container() {
    shared_folder=$1
    container_name=${2:-zsh_dev_container}

    info "Setting shared folder to $shared_folder"
    info "Setting container name to $container_name"

    if SHARED_FOLDER="$shared_folder" docker-compose -f .devcontainer/docker-compose.yml up -d --build; then
        success "Docker container successfully set up"
    else
        log_error "Could not set up Docker container"
    fi

    if docker exec -it "$container_name" /bin/zsh; then
        success "Interactive shell in container $container_name started"
    else
        log_error "Could not enter Docker container"
    fi
}

# Install dotfiles locally
install_dotfiles_local() {
    if [ -d "$DOTFILES_DIR" ]; then
        info "Dotfiles directory already exists"
    else
        info "Creating dotfiles directory"
        mkdir -p "$DOTFILES_DIR" || log_error "Could not create dotfiles directory"
    fi

    initialize_repo

    info "Cloning remote repository from $REPO_URL"
    if git --git-dir="$GIT_DIR" remote get-url origin &>/dev/null; then
        warn "Remote repository 'origin' already exists. Updating remote URL."
        git --git-dir="$GIT_DIR" remote set-url origin "$REPO_URL" || log_error "Could not update remote repository URL"
    else
        git --git-dir="$GIT_DIR" remote add origin "$REPO_URL" || log_error "Could not add remote repository"
    fi

    git --git-dir="$GIT_DIR" --work-tree="$HOME" fetch origin || log_error "Could not clone dotfiles"

    if ! git --git-dir="$GIT_DIR" --work-tree="$HOME" ls-remote --exit-code --heads origin main &>/dev/null; then
        log_error "Branch 'origin/main' does not exist in the remote repository."
    fi

    git --git-dir="$GIT_DIR" --work-tree="$HOME" fetch --all

    # Set pull strategy and perform pull
    git --git-dir="$GIT_DIR" --work-tree="$HOME" config pull.rebase false
    git --git-dir="$GIT_DIR" --work-tree="$HOME" pull origin main || log_error "Could not clone dotfiles"

    backup_dotfiles

    git --git-dir="$GIT_DIR" --work-tree="$HOME" reset --hard origin/main || log_error "Could not check out dotfiles"
    git --git-dir="$GIT_DIR" --work-tree="$HOME" checkout -f main || log_error "Could not check out dotfiles"

    info "Adding .dotfiles to .gitignore"
    echo ".dotfiles" >> "$HOME/.gitignore"

    info "Dotfiles installation completed"
}

# Main logic
main() {
    check_dependencies $1

    if [[ $1 == "--local" ]]; then
        install_dotfiles_local
    elif [[ $1 == "--docker" ]]; then
        default_shared_folder="$HOME/docker_shared"
        setup_docker_container "$default_shared_folder"
    else
        echo "Invalid option. Use --local or --docker."
        exit 1
    fi
}

# Setup exit trap to clean up script
cleanup() {
    info "Removing the script"
    if [[ -f "$0" ]]; then
        rm -- "$0"
    fi
}
trap cleanup EXIT

# Start script
main "$@"


