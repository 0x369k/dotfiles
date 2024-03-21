#!/usr/bin/env bash

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths and default values
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"

# Safe exit function
safe_exit() {
  local message="$1"
  echo -e "[${RED}✘${NC}] Error: ${message}"
  [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
  exit 1
}

# Backup files function
backup_files() {
  echo -e "[${BLUE}i${NC}] Creating backup directory: ${BACKUP_DIR}"
  mkdir -p "${BACKUP_DIR}"

  echo -e "[${BLUE}i${NC}] Cloning dotfiles repository..."
  git clone --depth=1 "${DOTFILES_REPO}" "${TEMP_DIR}" || safe_exit "Error while cloning the dotfiles repository"
  echo -e "[${GREEN}✔${NC}] Dotfiles repository cloned successfully."

  cd "${TEMP_DIR}" || safe_exit "Error while navigating to the temporary directory"

  while IFS= read -r -d '' file; do
    relative_path="${file#"${TEMP_DIR}/"}"
    target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
    mkdir -p "${target_dir}"

    if [ -e "${HOME}/${relative_path}" ]; then
      echo -e "[${YELLOW}i${NC}] Backing up: ${HOME}/${relative_path}"
      mv "${HOME}/${relative_path}" "${target_dir}/"
    fi
  done < <(find "${TEMP_DIR}" -type f -print0)

  rm -rf "${TEMP_DIR}"
}

# Initialize and checkout dotfiles function
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

# Deploy in a Docker container function
deploy_docker() {
  local container_name="${1:-devcontainer}"
  local image_name="${2:-default_image_name}"
  local base_image="${3:-archlinux:latest}"

  image_name=$(echo "${image_name}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
  base_image=$(echo "${base_image}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')

  echo -e "[${BLUE}i${NC}] Downloading docker-compose.yml..."
  curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml -o docker-compose.yml || safe_exit "Error while downloading docker-compose.yml"
  echo -e "[${GREEN}✔${NC}] docker-compose.yml downloaded successfully."

  sed -i "s/\${IMAGE_NAME:-default-image-name}/${image_name}/g" docker-compose.yml
  sed -i "s/\${BASE_IMAGE:-archlinux:latest}/${base_image}/g" docker-compose.yml

  echo -e "[${BLUE}i${NC}] Starting Docker container..."
  docker-compose up -d || safe_exit "Error while starting the Docker container"
  echo -e "[${GREEN}✔${NC}] Docker container started successfully."
  echo -e "You can enter the container with ${YELLOW}docker exec -it ${container_name} /usr/bin/zsh${NC}"
}

# Parse arguments function
parse_arguments() {
  while [[ $# -gt 0 ]];    case "$1" in
      --local)
        deploy_mode="local"
        shift
        ;;
      --docker)
        deploy_mode="docker"
        container_name="$2"
        image_name="$3"
        base_image="$4"
        shift 4
        ;;
      *)
        safe_exit "Invalid argument: $1"
        ;;
    esac
  done
}

# Main execution function
main() {
  parse_arguments "$@"

  case "${deploy_mode}" in
    local)
      backup_files
      initialize_and_checkout_dotfiles
      echo -e "[${GREEN}✔${NC}] Local deployment completed successfully."
      ;;
    docker)
      deploy_docker "${container_name}" "${image_name}" "${base_image}"
      ;;
    *)
      safe_exit "Invalid deployment mode: ${deploy_mode}"
      ;;
  esac
}

main "$@"