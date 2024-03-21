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
  echo -e "${RED}Error: ${message}${NC}"
  [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
  exit 1
}

# Backup files function
backup_files() {
  echo -e "${BLUE}Creating backup directory: ${BACKUP_DIR}${NC}"
  mkdir -p "${BACKUP_DIR}"

  for dir in ".zi" ".zsh" ".dotfiles"; do
    if [ -d "${HOME}/${dir}" ]; then
      echo -e "${YELLOW}Backing up directory: ${HOME}/${dir}${NC}"
      mv "${HOME}/${dir}" "${BACKUP_DIR}/"
    fi
  done

  for file in ".zshrc" ".zshenv"; do
    if [ -e "${HOME}/${file}" ]; then
      echo -e "${YELLOW}Backing up file: ${HOME}/${file}${NC}"
      mv "${HOME}/${file}" "${BACKUP_DIR}/"
    fi
  done

  echo -e "${BLUE}Cloning dotfiles repository...${NC}"
  git clone --depth=1 "${DOTFILES_REPO}" "${TEMP_DIR}" || safe_exit "Error while cloning the dotfiles repository"
  echo -e "${GREEN}Dotfiles repository cloned successfully.${NC}"

  echo -e "${BLUE}Copying dotfiles to backup directory...${NC}"
  cp -r "${TEMP_DIR}"/* "${BACKUP_DIR}/"
  echo -e "${GREEN}Dotfiles copied to backup directory successfully.${NC}"

  rm -rf "${TEMP_DIR}"
}

# Initialize and checkout dotfiles function
initialize_and_checkout_dotfiles() {
  if [ -d "${DOTDIR}" ]; then
    echo -e "${YELLOW}Moving existing ${DOTDIR} to backup directory...${NC}"
    mv "${DOTDIR}" "${BACKUP_DIR}/"
    echo -e "${GREEN}Existing ${DOTDIR} moved to backup directory successfully.${NC}"
  fi

  echo -e "${BLUE}Cloning bare repository...${NC}"
  git clone --bare "${DOTFILES_REPO}" "${DOTDIR}" || safe_exit "Error while cloning the bare repository"
  echo -e "${GREEN}Bare repository cloned successfully.${NC}"

  git --git-dir="${DOTDIR}" --work-tree="${HOME}" config --local status.showUntrackedFiles no

  echo -e "${BLUE}Checking out dotfiles...${NC}"
  git --git-dir="${DOTDIR}" --work-tree="${HOME}" checkout || safe_exit "Error while checking out the dotfiles"
  echo -e "${GREEN}Dotfiles checked out successfully.${NC}"
}

# Deploy in a Docker container function
deploy_docker() {
  local container_name="${1:-devcontainer}"
  local image_name="${2:-default_image_name}"
  local base_image="${3:-archlinux:latest}"

  image_name=$(echo "${image_name}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
  base_image=$(echo "${base_image}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')

  echo -e "${BLUE}Downloading docker-compose.yml...${NC}"
  curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml -o docker-compose.yml || safe_exit "Error while downloading docker-compose.yml"
  echo -e "${GREEN}docker-compose.yml downloaded successfully.${NC}"

  sed -i "s/\${IMAGE_NAME:-default-image-name}/${image_name}/g" docker-compose.yml
  sed -i "s/\${BASE_IMAGE:-archlinux:latest}/${base_image}/g" docker-compose.yml

  echo -e "${BLUE}Starting Docker container...${NC}"
  docker-compose up -d || safe_exit "Error while starting the Docker container"
  echo -e "${GREEN}Docker container started successfully.${NC}"
  echo -e "You can enter the container with ${YELLOW}docker exec -it ${container_name} /usr/bin/zsh${NC}"
}

# Parse arguments function
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
      echo -e "${GREEN}Local deployment completed successfully.${NC}"
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