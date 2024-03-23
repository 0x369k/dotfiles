#!/usr/bin/env bash

# Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repositories and file URLs
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"
LOG_FILE="/tmp/deploy.log"

log_message() {
    local message="$1"
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# Enhanced safe_exit function with error logging
safe_exit() {
    local message="$1"
    local code="${2:-1}" # Default exit status 1
    echo -e "[${RED}✘${NC}] Error: ${message}" | tee -a "$LOG_FILE"
    [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
    exit "$code"
}

execute_command() {
    local command="$1"
    local message="$2"
    local ignore_error="${3:-false}"

    echo -e "[${BLUE}i${NC}] $message"
    log_message "$message"

    if $ignore_error; then
        eval "$command" 2>>"$LOG_FILE" || true
    else
        eval "$command" 2>>"$LOG_FILE" || safe_exit "Failed to execute: $command" 2
    fi
}

backup_files() {
   log_message "[i] Creating backup directory: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}" || safe_exit "Could not create backup directory"

    log_message "[i] Cloning dotfiles repository..."
    execute_command "git clone --depth=1 \"${DOTFILES_REPO}\" \"${TEMP_DIR}\"" "Cloning dotfiles repository..."
    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" checkout" "Checking out dotfiles..."

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
        execute_command "mv \"${DOTDIR}\" \"${BACKUP_DIR}/\"" "Moving existing ${DOTDIR} to backup directory..."
    fi
    execute_command "git clone --bare \"${DOTFILES_REPO}\" \"${DOTDIR}\"" "Cloning bare repository..."
    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" config --local status.showUntrackedFiles no" "Configuring dotfiles..."
    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" checkout" "Checking out dotfiles..."
}

main() {
    log_message "[i] Starting deployment script..."
    backup_files
    initialize_and_checkout_dotfiles
    log_message "[✔] Deployment completed successfully."
}

main "$@"