#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOCKER_COMPOSE_FILE_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml"
DOCKERFILE_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/Dockerfile"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"

safe_exit() {
  local message="$1"
  echo -e "[${RED}✘${NC}] Error: ${message}"
  [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
  exit 1
}

backup_files() {
  echo -e "[${BLUE}i${NC}] Creating backup directory: ${BACKUP_DIR}"
  mkdir -p "${BACKUP_DIR}"
  echo -e "[${BLUE}i${NC}] Cloning dotfiles repository..."
  git clone --depth=1 "${DOTFILES_REPO}" "${TEMP_DIR}" || safe_exit "Error while cloning the dotfiles repository"
  echo -e "[${GREEN}✔${NC}] Dotfiles repository cloned successfully."
  while IFS= read -r -d '' file; do
    relative_path="${file#"${TEMP_DIR}/"}"
    target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
    mkdir -p "${target_dir}"
    if [ -e "${HOME}/${relative_path}" ]; then
      echo -e "[${YELLOW}i${NC}] Backing up: ${HOME}/${relative_path}"
      mv "${HOME}/${relative_path}" "${target_dir}/"
    fi
  done < <(find "${TEMP_DIR}" -type f -print0)
  for dir in ".zi"; do
    if [ -d "${HOME}/${dir}" ]; then
      echo -e "[${YELLOW}i${NC}] Backing up directory: ${HOME}/${dir}"
      mv "${HOME}/${dir}" "${BACKUP_DIR}/"
    fi
  done
  for file in ".zshrc" ".zshenv" ".zprofile" ".zlogin" ".zlogout" ".zsh_history"; do
    if [ -e "${HOME}/${file}" ]; then
      echo -e "[${YELLOW}i${NC}] Backing up file: ${HOME}/${file}"
      mv "${HOME}/${file}" "${BACKUP_DIR}/"
    fi
  done
  rm -rf "${TEMP_DIR}"
}

initialize_and_checkout_dotfiles() {
  if [ -d "${DOTDIR}" ]; then
    echo -e "[${YELLOW}i${NC}] Moving existing ${DOTDIR} to backup directory..."
    mv "${DOTDIR}" "${BACKUP_DIR}/"
    echo -e "[${GREEN}✔${NC}] Existing ${DOTDIR} moved to backup directory successfully."
  fi
  echo -e "[${BLUE}i${NC}] Cloning bare repository..."
  git clone --bare "${DOTFILES_REPO}" "${DOTDIR}" || safe_exit "Error while cloning the bare repository"
  echo -e "[${GREEN}✔${NC}] Bare repository cloned successfully."
  git --git-dir="${DOTDIR}" --work-tree="${HOME}" config --local status.showUntrackedFiles no
  echo -e "[${BLUE}i${NC}] Checking out dotfiles..."
  git --git-dir="${DOTDIR}" --work-tree="${HOME}" checkout || safe_exit "Error while checking out the dotfiles"
  echo -e "[${GREEN}✔${NC}] Dotfiles checked out successfully."
}

deploy_docker() {
  local container_name="${1:-devcontainer}"
  local image_name="${2:-default_image_name}"
  local base_image="${3:-archlinux:latest}"
  local current_dir=$(pwd)

  echo "Container Name: $container_name"
  echo "Image Name: $image_name"
  echo "Base Image: $base_image"
  echo "Current Directory: $current_dir"

  mkdir -p "$TEMP_DIR"
  curl -Lks "$DOCKERFILE_URL" -o "$TEMP_DIR/Dockerfile" || safe_exit "Error downloading Dockerfile"
  curl -Lks "$DOCKER_COMPOSE_FILE_URL" -o "$TEMP_DIR/docker-compose.yml" || safe_exit "Error downloading docker-compose.yml"

  local default_base_image=$(grep 'ARG BASE_IMAGE=' "$TEMP_DIR/Dockerfile" | cut -d'=' -f2)

  # Überprüfe, ob ein benutzerdefiniertes Base-Image übergeben wurde
  if [[ "$base_image" != "$default_base_image" ]]; then
    sed -i "s|ARG BASE_IMAGE=.*|ARG BASE_IMAGE=$base_image|" "$TEMP_DIR/Dockerfile"
  fi

  sed -i "s|{{IMAGE_NAME}}|$image_name|g" "$TEMP_DIR/docker-compose.yml"
  sed -i "s|{{CONTAINER_NAME}}|$container_name|g" "$TEMP_DIR/docker-compose.yml"
  sed -i "s|- .:/home/developer:cached|- $current_dir:/home/developer/workspace:cached|g" "$TEMP_DIR/docker-compose.yml"

  docker-compose -f "$TEMP_DIR/docker-compose.yml" up -d --build || safe_exit "Failed to start Docker container"
  echo "Docker container $container_name started. You can enter with 'docker exec -it $container_name /usr/bin/zsh'"
  rm -rf "$TEMP_DIR"
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --docker)
        DEPLOY_MODE="docker"
        shift

        if [[ -n "$1" && "$1" != "--"* ]]; then
          CUSTOM_CONTAINER_NAME="$1"
          shift
        fi

        if [[ -n "$1" && "$1" != "--"* ]]; then
          CUSTOM_IMAGE_NAME="$1"
          shift
        fi

        if [[ -n "$1" && "$1" != "--"* ]]; then
          CUSTOM_BASE_IMAGE="$1"
          shift
        fi
        ;;
      --local)
        DEPLOY_MODE="local"
        shift
        ;;
      *)
        echo "Unbekanntes Argument: $1"
        exit 1
        ;;
    esac
  done
}

main() {
DEPLOY_MODE="local"
parse_arguments "$@"

case "${DEPLOY_MODE}" in
local)
backup_files
initialize_and_checkout_dotfiles
echo -e "[${GREEN}✔${NC}] Local deployment completed successfully."
;;
docker)
deploy_docker "${CUSTOM_CONTAINER_NAME:-devcontainer}" "${CUSTOM_IMAGE_NAME:-default_image_name}" "${CUSTOM_BASE_IMAGE:-archlinux:latest}"
;;
*)
echo -e "[${RED}✘${NC}] Error: Invalid deployment mode: ${DEPLOY_MODE}"
exit 1
;;
esac
}

main "$@"