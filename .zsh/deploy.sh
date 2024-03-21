#!/usr/bin/env bash

# Farbdefinitionen
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Pfade und Standardwerte
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"

safe_exit() {
  local message="$1"
  echo -e "${RED}Fehler: ${message}${NC}"
  [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
  exit 1
}

# Sichern von Dateien
backup_files() {
  mkdir -p "${BACKUP_DIR}"
  for file in ".zshrc" ".zshenv"; do
    [ -e "${HOME}/${file}" ] && cp -r "${HOME}/${file}" "${BACKUP_DIR}/"
  done

  git clone --depth=1 "${DOTFILES_REPO}" "${TEMP_DIR}" || safe_exit "Fehler beim Klonen des Dotfiles-Repositorys"
  cp -r "${TEMP_DIR}/dotfiles/"* "${BACKUP_DIR}/"
  rm -rf "${TEMP_DIR}"
}

# Initialisierung und Auschecken von Dotfiles
initialize_and_checkout_dotfiles() {
  [ -d "${DOTDIR}" ] && rm -rf "${DOTDIR}"
  git clone --bare "${DOTFILES_REPO}" "${DOTDIR}" || safe_exit "Fehler beim Klonen des Bare-Repositorys"
  git --git-dir="${DOTDIR}" --work-tree="${HOME}" config --local status.showUntrackedFiles no
  git --git-dir="${DOTDIR}" --work-tree="${HOME}" checkout || safe_exit "Fehler beim Auschecken der Dotfiles"
}

# Bereitstellung in einem Docker-Container
deploy_docker() {
  local container_name="${1:-default_container_name}"
  local image_name="${2:-default_image_name}"
  local base_image="${3:-archlinux:latest}"

  command -v docker-compose >/dev/null 2>&1 || safe_exit "docker-compose ist nicht installiert"

  curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml -o docker-compose.yml || safe_exit "Fehler beim Herunterladen der docker-compose.yml"
  sed -i "s/\${IMAGE_NAME:-default-image-name}/${image_name}/g" docker-compose.yml
  sed -i "s/\${BASE_IMAGE:-archlinux:latest}/${base_image}/g" docker-compose.yml
  sed -i "s/\${UID:-1000}/${UID}/g" docker-compose.yml
  sed -i "s/\${GID:-1000}/${GID}/g" docker-compose.yml
  docker-compose up -d || safe_exit "Fehler beim Starten des Docker-Containers"
}

# Aufräumen von Docker-Ressourcen
cleanup_docker() {
  docker-compose down --remove-orphans
  rm -f docker-compose.yml
}

# Argumentenverarbeitung
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
            safe_exit "Ungültiges Argument: $1"
            ;;
        esac
    done
}

main() {
  parse_arguments "$@"

  case "${deploy_mode}" in
    local)
      backup_files
      initialize_and_checkout_dotfiles
      echo -e "${GREEN}Lokale Bereitstellung erfolgreich abgeschlossen.${NC}"
      ;;
    docker)
      deploy_docker "${container_name}" "${image_name}" "${base_image}"
      echo -e "${GREEN}Docker-Bereitstellung erfolgreich abgeschlossen.${NC}"
      cleanup_docker
      ;;
    *)
      safe_exit "Ungültiger Bereitstellungsmodus: ${deploy_mode}"
      ;;
  esac
}

main "$@"