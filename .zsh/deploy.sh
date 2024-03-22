#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository and file URLs
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOCKER_COMPOSE_FILE_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml"
DOCKERFILE_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/Dockerfile"

# Directories
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"
LOG_FILE="/tmp/deploy.log"

log() {
    local message="$1"
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >>"$LOG_FILE"
}

safe_exit() {
    local message="$1"
    echo -e "[${RED}✘${NC}] Error: ${message}"
    log "[${RED}✘${NC}] Error: ${message}"
    [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
    exit 1
}

backup_files() {
    echo -e "[${BLUE}i${NC}] Creating backup directory: ${BACKUP_DIR}"
    log "[${BLUE}i${NC}] Creating backup directory: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"
    echo -e "[${BLUE}i${NC}] Cloning dotfiles repository..."
    log "[${BLUE}i${NC}] Cloning dotfiles repository..."
    git clone --depth=1 "${DOTFILES_REPO}" "${TEMP_DIR}" || safe_exit "Error while cloning the dotfiles repository"
    echo -e "[${GREEN}✔${NC}] Dotfiles repository cloned successfully."
    log "[${GREEN}✔${NC}] Dotfiles repository cloned successfully."

    while IFS= read -r -d '' file; do
        relative_path="${file#"${TEMP_DIR}/"}"
        target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
        mkdir -p "${target_dir}"
        if [ -e "${HOME}/${relative_path}" ]; then
            echo -e "[${YELLOW}i${NC}] Backing up: ${HOME}/${relative_path}"
            log "[${YELLOW}i${NC}] Backing up: ${HOME}/${relative_path}"
            mv "${HOME}/${relative_path}" "${target_dir}/"
        fi
    done < <(find "${TEMP_DIR}" -type f -print0)

    for dir in ".zi"; do
        if [ -d "${HOME}/${dir}" ]; then
            echo -e "[${YELLOW}i${NC}] Backing up directory: ${HOME}/${dir}"
            log "[${YELLOW}i${NC}] Backing up directory: ${HOME}/${dir}"
            mv "${HOME}/${dir}" "${BACKUP_DIR}/"
        fi
    done

    for file in ".zshrc" ".zshenv" ".zprofile" ".zlogin" ".zlogout" ".zsh_history"; do
        if [ -e "${HOME}/${file}" ]; then
            echo -e "[${YELLOW}i${NC}] Backing up file: ${HOME}/${file}"
            log "[${YELLOW}i${NC}] Backing up file: ${HOME}/${file}"
            mv "${HOME}/${file}" "${BACKUP_DIR}/"
        fi
    done

    rm -rf "${TEMP_DIR}"
}

initialize_and_checkout_dotfiles() {
    if [ -d "${DOTDIR}" ]; then
        echo -e "[${YELLOW}i${NC}] Moving existing ${DOTDIR} to backup directory..."
        log "[${YELLOW}i${NC}] Moving existing ${DOTDIR} to backup directory..."
        mv "${DOTDIR}" "${BACKUP_DIR}/"
        echo -e "[${GREEN}✔${NC}] Existing ${DOTDIR} moved to backup directory successfully."
        log "[${GREEN}✔${NC}] Existing ${DOTDIR} moved to backup directory successfully."
    fi
    echo -e "[${BLUE}i${NC}] Cloning bare repository..."
    log "[${BLUE}i${NC}] Cloning bare repository..."
    git clone --bare "${DOTFILES_REPO}" "${DOTDIR}" || safe_exit "Error while cloning the bare repository"
    echo -e "[${GREEN}✔${NC}] Bare repository cloned successfully."
    log "[${GREEN}✔${NC}] Bare repository cloned successfully."
    git --git-dir="${DOTDIR}" --work-tree="${HOME}" config --local status.showUntrackedFiles no
    echo -e "[${BLUE}i${NC}] Checking out dotfiles..."
    log "[${BLUE}i${NC}] Checking out dotfiles..."
    git --git-dir="${DOTDIR}" --work-tree="${HOME}" checkout || safe_exit "Error while checking out the dotfiles"
    echo -e "[${GREEN}✔${NC}] Dotfiles checked out successfully."
    log "[${GREEN}✔${NC}] Dotfiles checked out successfully."
}

load_config() {
    local env_file=".devcontainer/.env"
    # Load default values from the remote file
    curl -Lks "https://raw.githubusercontent.com/0x369k/dotfiles/main/${env_file}" -o "/tmp/.env" || safe_exit "Error downloading ${env_file}"
    source "/tmp/.env"
    # Override default values with values from the local file, if available
    if [ -f "${env_file}" ]; then
        echo -e "[${BLUE}i${NC}] Loading configuration from ${env_file}"
        log "[${BLUE}i${NC}] Loading configuration from ${env_file}"
        source "${env_file}"
    else
        echo -e "[${YELLOW}i${NC}] Local configuration not found, using default values."
        log "[${YELLOW}i${NC}] Local configuration not found, using default values."
    fi
}

check_existing_container() {
    local container_name="$1"
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}\$"; then
        echo -e "[${YELLOW}!${NC}] Container ${container_name} already exists."
        log "[${YELLOW}!${NC}] Container ${container_name} already exists."
        read -p "Do you want to remove the existing container? [y/N]: " remove_container
        if [[ "${remove_container,,}" =~ ^(y|yes)$ ]]; then
            docker rm -f "${container_name}"
            echo -e "[${GREEN}✔${NC}] Removed existing container ${container_name}."
            log "[${GREEN}✔${NC}] Removed existing container ${container_name}."
        else
            safe_exit "Deployment aborted due to existing container."
        fi
    fi
}

deploy_docker() {
local container_name="${CUSTOM_CONTAINER_NAME}"
local image_name="${CUSTOM_IMAGE_NAME}"
local base_image="${CUSTOM_BASE_IMAGE}"
local current_dir=$(pwd)
local username="${CUSTOM_USERNAME}"
echo -e "[${BLUE}i${NC}] Container Name: ${container_name}"
log "[${BLUE}i${NC}] Container Name: ${container_name}"
echo -e "[${BLUE}i${NC}] Image Name: ${image_name}"
log "[${BLUE}i${NC}] Image Name: ${image_name}"
echo -e "[${BLUE}i${NC}] Base Image: ${base_image}"
log "[${BLUE}i${NC}] Base Image: ${base_image}"
echo -e "[${BLUE}i${NC}] Current Directory: ${current_dir}"
log "[${BLUE}i${NC}] Current Directory: ${current_dir}"
echo -e "[${BLUE}i${NC}] Username: ${username}"
log "[${BLUE}i${NC}] Username: ${username}"
mkdir -p "$TEMP_DIR"
curl -Lks "$DOCKERFILE_URL" -o "$TEMP_DIR/Dockerfile" || safe_exit "Error downloading Dockerfile"
log "[${GREEN}✔${NC}] Downloaded Dockerfile"
curl -Lks "$DOCKER_COMPOSE_FILE_URL" -o "$TEMP_DIR/docker-compose.yml" || safe_exit "Error downloading docker-compose.yml"
log "[${GREEN}✔${NC}] Downloaded docker-compose.yml"
curl -Lks "https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/package_manager_wrapper.sh" -o "$TEMP_DIR/package_manager_wrapper.sh" || safe_exit "Error downloading package_manager_wrapper.sh"
log "[${GREEN}✔${NC}] Downloaded package_manager_wrapper.sh"
local default_base_image=$(grep 'ARG BASE_IMAGE=' "$TEMP_DIR/Dockerfile" | cut -d'=' -f2)
if [[ "$base_image" != "$default_base_image" ]]; then
sed -i "s|ARG BASE_IMAGE=.*|ARG BASE_IMAGE=$base_image|" "$TEMP_DIR/Dockerfile"
log "Customized base image: $base_image"
fi
sed -i "s|{{IMAGE_NAME}}|$image_name|g" "$TEMP_DIR/docker-compose.yml"
log "Set image name to: $image_name"
sed -i "s|{{CONTAINER_NAME}}|$container_name|g" "$TEMP_DIR/docker-compose.yml"
log "Set container name to: $container_name"
sed -i "s|- .:/home/developer:cached|- $current_dir:/home/$username/workspace:cached|g" "$TEMP_DIR/docker-compose.yml"
log "Set volume mount to: $current_dir:/home/$username/workspace:cached"
sed -i "s|developer|$username|g" "$TEMP_DIR/Dockerfile"
log "Set username to: $username"
check_existing_container "$container_name"
docker-compose -f "$TEMP_DIR/docker-compose.yml" up -d --build || safe_exit "Failed to start Docker container"
local container_name=$(get_container_name)
local image_name=$(docker inspect --format='{{.Config.Image}}' "$container_name")
echo -e "[${GREEN}✔${NC}] Docker container $container_name started with image $image_name"
log "[${GREEN}✔${NC}] Docker container $container_name started with image $image_name"
echo "Docker container $container_name started. You can enter with 'docker exec -it $container_name /usr/bin/zsh'"
rm -rf "$TEMP_DIR"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --docker)
            DEPLOY_MODE="docker"
            shift
            ;;
        --local)
            DEPLOY_MODE="local"
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            log "Unknown argument: $1"
            exit 1
            ;;
        esac
    done
}

main() {
    DEPLOY_MODE="local"
    load_config
    parse_arguments "$@"
    case "${DEPLOY_MODE}" in
    local)
        backup_files
        initialize_and_checkout_dotfiles
        echo -e "[${GREEN}✔${NC}] Local deployment completed successfully."
        log "[${GREEN}✔${NC}] Local deployment completed successfully."
        ;;
    docker)
        deploy_docker
        ;;
    *)
        echo -e "[${RED}✘${NC}] Error: Invalid deployment mode: ${DEPLOY_MODE}"
        log "[${RED}✘${NC}] Error: Invalid deployment mode: ${DEPLOY_MODE}"
        exit 1
        ;;
    esac
}

main "$@"
