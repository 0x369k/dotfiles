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

safe_exit() {
    echo -e "${RED}[✖]${NC} An error occurred. Exiting safely..."
    echo "Error details: $1"
    rm -rf "$TMP_DOCKER_COMPOSE_DIR"
    exit 1
}

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


TMP_DOCKER_COMPOSE_DIR=$(mktemp -d) # Korrektur: Definition des temporären Verzeichnisses

deploy_docker() {
    local IMAGE_NAME="${1:-$DEFAULT_IMAGE_NAME}"
    local BASE_IMAGE="${2:-archlinux:latest}" # Anpassung, um eine Standard-Basis-Image zu setzen
    local CONTAINER_NAME="${3:-$DEFAULT_CONTAINER_NAME}"

    echo "❯ Deploying dotfiles in Docker container using docker-compose..."

    curl -Lks "$DOCKER_COMPOSE_FILE_URL" -o "$TMP_DOCKER_COMPOSE_DIR/docker-compose.yml" || safe_exit "Failed to download docker-compose.yml."

    # Ersetze Platzhalter direkt in der heruntergeladenen docker-compose.yml
    sed -i "s|{{IMAGE_NAME}}|$IMAGE_NAME|g" "$TMP_DOCKER_COMPOSE_DIR/docker-compose.yml"
    sed -i "s|{{BASE_IMAGE}}|$BASE_IMAGE|g" "$TMP_DOCKER_COMPOSE_DIR/docker-compose.yml"
    sed -i "s|{{CONTAINER_NAME}}|$CONTAINER_NAME|g" "$TMP_DOCKER_COMPOSE_DIR/docker-compose.yml"

    docker-compose -f "$TMP_DOCKER_COMPOSE_DIR/docker-compose.yml" up -d || safe_exit "Failed to deploy using docker-compose."

    rm -rf "$TMP_DOCKER_COMPOSE_DIR" # Bereinigung nach der Ausführung
}

parse_arguments() {
    DEPLOY_MODE="local"
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --docker)
                DEPLOY_MODE="docker"
                shift # Entfernt --docker
                CUSTOM_CONTAINER_NAME="${1:-$DEFAULT_CONTAINER_NAME}"
                shift
                CUSTOM_IMAGE_NAME="${1:-$DEFAULT_IMAGE_NAME}"
                shift
                CUSTOM_BASE_IMAGE="${1:-archlinux:latest}"
                ;;
            --local) 
                DEPLOY_MODE="local"
                ;;
            *) 
                echo -e "${RED}Unknown argument: $1${NC}"
                exit 1
                ;;
        esac
        shift
    done
}


main() {
        TMP_DOCKER_COMPOSE_DIR=$(mktemp -d) # Stelle sicher, dass ein temporäres Verzeichnis für jede Ausführung erstellt wird
    parse_arguments "$@"

    echo "Deployment mode: ${DEPLOY_MODE}"
    
    if [ "${DEPLOY_MODE}" == "docker" ]; then
        deploy_docker "$CUSTOM_IMAGE_NAME" "$CUSTOM_BASE_IMAGE" "$CUSTOM_CONTAINER_NAME"
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
