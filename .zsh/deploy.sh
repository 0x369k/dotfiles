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
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
DOTFILES_REPO="https://github.com/0x369k/dotfiles"
DOTDIR="${HOME}/.dotfiles"
DEFAULT_BRANCH="main"
BACKUPDIR="${HOME}/.dotfiles-backup/$(date +"%Y-%m-%d_%H-%M-%S")"
DEFAULT_IMAGE_NAME="archlinux-dev:latest"
DEFAULT_CONTAINER_NAME="archlinux-dev-container"
DOCKER_COMPOSE_FILE_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml"
TMP_DOCKER_COMPOSE_FILE="./docker-compose.yml"

# Funktion für sichere Exits mit Fehlermeldung
safe_exit() {
    echo -e "${RED}[✖]${NC} An error occurred. Exiting safely..."
    echo "Error details: $1"
    exit 1
}

# Funktion zum Sichern von Dateien
backup_files() {
    echo "❯ Backing up configuration files and directories..."
    mkdir -p "${BACKUPDIR}" || safe_exit "Could not create backup directory: ${BACKUPDIR}"
    local LOCAL_CONFIG_FILES=(".zshrc" ".zshenv" ".zprofile" ".zlogin" ".zlogout" ".zsh_history")
    local ZI_DIR=".zi"

    for file in "${LOCAL_CONFIG_FILES[@]}"; do
        if [ -f "${HOME}/${file}" ]; then
            mv "${HOME}/${file}" "${BACKUPDIR}/${file}" && echo -e "${GREEN}[✔]${NC} ${file} successfully backed up."
        else
            echo -e "${YELLOW}Warning: ${file} does not exist and will be skipped.${NC}"
        fi
    done

    if [ -d "${HOME}/${ZI_DIR}" ]; then
        mv "${HOME}/${ZI_DIR}" "${BACKUPDIR}/${ZI_DIR}" && echo -e "${GREEN}[✔]${NC} ${ZI_DIR} directory successfully backed up."
    else
        echo -e "${YELLOW}Warning: ${ZI_DIR} directory does not exist and will be skipped.${NC}"
    fi

    echo "${GREEN}Attempting to backup dotfiles managed by the repository...${NC}"
    git clone "${DOTFILES_REPO}" "${TEMP_CLONE_DIR}" || safe_exit "Failed to clone the dotfiles repository temporarily."
    (cd "${TEMP_CLONE_DIR}" && git ls-tree --full-tree -r --name-only HEAD) | while read file; do
        if [ -e "${HOME}/${file}" ]; then
            local dir_path=$(dirname "${file}")
            mkdir -p "${BACKUPDIR}/${dir_path}"
            mv "${HOME}/${file}" "${BACKUPDIR}/${file}" && echo -e "${GREEN}[✔]${NC} ${file} successfully backed up."
        fi
    done
    rm -rf "${TEMP_CLONE_DIR}"
    echo -e "${GREEN}[✔]${NC} All configuration files backed up."
}

initialize_and_checkout_dotfiles() {
    echo "Initializing dotfiles repository..."
    if [ ! -d "${DOTDIR}" ]; then
        git clone --bare "${DOTFILES_REPO}" "${DOTDIR}" || safe_exit "Failed to clone the dotfiles repository."
    fi
    /usr/bin/git --git-dir=${DOTDIR} --work-tree=${HOME} config --local status.showUntrackedFiles no
    /usr/bin/git --git-dir=${DOTDIR} --work-tree=${HOME} reset --hard "origin/${DEFAULT_BRANCH}"
    echo -e "${GREEN}[✔]${NC} Dotfiles repository initialized and checked out."
}

deploy_docker() {
    local IMAGE_NAME=${1:-$DEFAULT_IMAGE_NAME}
    local BASE_IMAGE=${2:-$DEFAULT_BASE_IMAGE}
    
    echo "❯ Deploying dotfiles in Docker container using docker-compose..."

    # Prüfe, ob docker-compose installiert und verfügbar ist
    if ! command -v docker-compose &>/dev/null; then
        safe_exit "docker-compose is not installed or not available in PATH."
    fi

    # Download the docker-compose.yml file temporarily
    curl -Lks "$DOCKER_COMPOSE_FILE_URL" -o "$TMP_DOCKER_COMPOSE_FILE" || safe_exit "Failed to download docker-compose.yml temporarily."

    # Anpassen der docker-compose.yml für benutzerdefinierte Konfiguration
    sed -i "s|{{IMAGE_NAME}}|$IMAGE_NAME|g" "$TMP_DOCKER_COMPOSE_FILE"
    sed -i "s|{{BASE_IMAGE}}|$BASE_IMAGE|g" "$TMP_DOCKER_COMPOSE_FILE"
    sed -i "s|{{CONTAINER_NAME}}|$DEFAULT_CONTAINER_NAME|g" "$TMP_DOCKER_COMPOSE_FILE"

    # Bau und Start des Containers
    docker-compose -f "$TMP_DOCKER_COMPOSE_FILE" up -d || safe_exit "Failed to deploy using docker-compose."

    # Bereinigung
    rm "$TMP_DOCKER_COMPOSE_FILE" || echo "Warning: Failed to remove temporary docker-compose file."

    echo -e "${GREEN}[✔]${NC} Docker container $DEFAULT_CONTAINER_NAME started."
}

parse_arguments() {
    if [[ "$1" == "--docker" ]]; then
        shift # Entferne '--docker'
        DEPLOY_MODE="docker"
        if [ -n "$1" ]; then
            IMAGE_NAME="$1"
            shift # Entferne das optionale IMAGE_NAME Argument
        fi
        if [ -n "$1" ]; then
            BASE_IMAGE="$1"
            # BASE_IMAGE wird durch Argument überschrieben
        fi
    else
        DEPLOY_MODE="local"
    fi
}

main() {
    parse_arguments "$@"

    echo "Deployment mode: ${DEPLOY_MODE}"
    
    if [ "${DEPLOY_MODE}" == "docker" ]; then
        deploy_docker "$IMAGE_NAME" "$BASE_IMAGE"
    elif [ "${DEPLOY_MODE}" == "local" ]; then
        backup_files
        initialize_and_checkout_dotfiles
        echo -e "${GREEN}Dotfiles successfully deployed locally.${NC}"
    else
        echo -e "${RED}Invalid deployment mode selected.${NC}"
        exit 1
    fi
}

main "$@"
