#!/bin/bash
##########################################################################################################
#                          Dotfiles Backup und Installation
# Usage:
#   deploy.sh [OPTIONS]
#
# Options:
#   --docker         Deploy dotfiles in a Docker container
#   --local          Deploy dotfiles locally (default)
#
# Example:
#   curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh | bash -s -- --local
#   curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh | bash -s -- --docker
##########################################################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

DOTDIR="${HOME}/.dotfiles"
BACKUPDIR="${HOME}/.dotfiles-backup/$(date +"%Y-%m-%d_%H-%M-%S")"
ZSH_CONFIG_FILES=(".zshrc" ".zsh_history" ".zshenv" ".zlogin" ".zlogout" ".zprofile")
IMAGE_NAME="dotfiles-dev-container"
CONTAINER_NAME="dotfiles-testing"
DEFAULT_BRANCH="main"

# Checks if Docker is installed and exits if not found
check_docker_dependency() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}[✖]${NC} Docker not found. Please install Docker to continue."
        exit 1
    fi
}

# Safe exit with detailed error message
safe_exit() {
    echo -e "${RED}[✖]${NC} An error occurred. Exiting safely..."
    echo "Error details: $1"
    exit 1
}

# Backup function for .zsh files not tracked in the repository
backup_zsh_files() {
    echo "❯ Backing up .zsh configuration files and directories..."
    mkdir -p "${BACKUPDIR}" || safe_exit "Could not create directory for backup: ${BACKUPDIR}"
    for zsh_file in "${ZSH_CONFIG_FILES[@]}" ".zi" ".zsh"; do
        local file_path="${HOME}/${zsh_file}"
        local backup_path="${BACKUPDIR}/${zsh_file}"

        if [ -e "${file_path}" ]; then
            if ! mv -v "${file_path}" "${backup_path}"; then
                safe_exit "Error backing up ${file_path}"
            fi
            echo "✔ ${zsh_file} successfully backed up."
        else
            echo "File ${zsh_file} does not exist and will be skipped."
        fi
    done
}

# Improved backup function with detailed error checking
backup_dotfiles() {
    echo "❯ Backing up existing dotfiles..."
    mkdir -p "${BACKUPDIR}" || safe_exit "Could not create backup directory: ${BACKUPDIR}"

    git --git-dir="${DOTDIR}" --work-tree="${HOME}" ls-tree -r HEAD --name-only | while read -r repo_file; do
        local file_path="${HOME}/${repo_file}"
        local backup_path="${BACKUPDIR}/${repo_file}"

        if [ -e "${file_path}" ]; then
            mkdir -p "$(dirname "${backup_path}")" || safe_exit "Could not create directory for backup: $(dirname "${backup_path}")"
            if ! mv -v "${file_path}" "${backup_path}"; then
                safe_exit "Error backing up ${file_path}"
            fi
            echo "✔ ${repo_file} successfully backed up."
        else
            echo "File ${repo_file} does not exist and will be skipped."
        fi
    done
}

# Ensure any running container is stopped and removed
ensure_container_stopped() {
    if docker ps -a | grep -q "${CONTAINER_NAME}"; then
        echo "A container named '${CONTAINER_NAME}' already exists. It will be stopped and removed."
        docker stop "${CONTAINER_NAME}" > /dev/null && docker rm "${CONTAINER_NAME}" > /dev/null || safe_exit "Error stopping and removing container ${CONTAINER_NAME}"
    fi
}

# Function to verify and fix file transfer from the git repo
verify_and_fix_repo_files_transfer() {
    echo "❯ Verifying dotfiles transfer from the git repository..."
    local missing_files=0

    git --git-dir="${DOTDIR}" --work-tree="${HOME}" ls-tree -r HEAD --name-only | while read -r repo_file; do
        if [ ! -e "${HOME}/${repo_file}" ]; then
            echo "Missing ${repo_file}. Attempting to restore..."
            git --git-dir="${DOTDIR}" --work-tree="${HOME}" checkout HEAD -- "${repo_file}"
            missing_files=$((missing_files + 1))
        fi
    done

    if [ $missing_files -eq 0 ]; then
        echo "✔ All files successfully transferred."
    else
        echo "✔ Missing files attempted to be restored. Please check for any errors above."
    fi
}

# Install dotfiles locally
install_dotfiles_locally() {
    echo "❯ Installing dotfiles locally..."
    if [ ! -d "${DOTDIR}" ]; then
        echo "Dotfiles repository not found. Cloning..."
        git clone --bare https://github.com/0x369k/dotfiles "${DOTDIR}" || safe_exit "Failed to clone dotfiles repository."
    fi

    if git --git-dir="${DOTDIR}" --work-tree="${HOME}" checkout main; then
        git --git-dir="${DOTDIR}" --work-tree="${HOME}" config --local status.showUntrackedFiles no
        echo "Dotfiles successfully installed locally."
        verify_and_fix_repo_files_transfer
    else
        safe_exit "Error deploying dotfiles."
    fi
}

# Deploy dotfiles in a Docker container
deploy_dotfiles_to_docker() {
    ensure_container_stopped
    echo "Checking if Docker image exists..."
    if ! docker image inspect "${IMAGE_NAME}" > /dev/null 2>&1; then
        echo "Docker image '${IMAGE_NAME}' does not exist. Building now..."
        docker build -t "${IMAGE_NAME}" -f ~/.devcontainer/Dockerfile ~/.devcontainer || safe_exit "Error building Docker image."
    else
        echo "Docker image '${IMAGE_NAME}' already exists."
    fi

    docker run -dit --name "${CONTAINER_NAME}" "${IMAGE_NAME}" /bin/zsh || safe_exit "Error starting Docker container."
    echo "To enter the container, use: docker exec -it ${CONTAINER_NAME} /bin/zsh"
}

main() {
    MODE="local" # Default mode

    # Parse command-line options
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --docker) check_docker_dependency; MODE="docker"; ;;
            --local) MODE="local"; ;;
            *) echo "Unknown argument: $1"; exit 1 ;;
        esac
        shift
    done

    echo "Deployment mode: ${MODE}"

    # Execute based on the chosen mode
    if [ "$MODE" == "docker" ]; then
        deploy_dotfiles_to_docker
    elif [ "$MODE" == "local" ]; then
        backup_zsh_files
        backup_dotfiles
        install_dotfiles_locally
    else
        echo "Invalid mode selected."
        exit 1
    fi
}

main "$@"
