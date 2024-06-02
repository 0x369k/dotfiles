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

# Load configuration if available
CONFIG_FILE="${HOME}/.deploy_config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Logging function for general messages
log_message() {
    local status="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}[${status}] ${message}${NC}" | tee -a "$LOG_FILE"
}

# Enhanced safe_exit function with error logging
safe_exit() {
    local message="$1"
    local code="${2:-1}" # Default exit status 1
    log_message "✘ Error" "$message" "$RED"
    [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
    exit "$code"
}

# Enhanced error handling
execute_command() {
    local command="$1"
    local message="$2"
    local ignore_error="${3:-false}"

    log_message "i" "$message" "$BLUE"

    if $ignore_error; then
        eval "$command" 2>>"$LOG_FILE" || true
    else
        eval "$command" 2>>"$LOG_FILE" || safe_exit "Failed to execute: $command" 2
    fi
}

# Function to check and install dependencies
install_dependencies() {
    log_message "i" "Checking for required dependencies..." "$BLUE"
    if ! command -v git &> /dev/null; then
        log_message "i" "git is not installed. Installing git..." "$BLUE"
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy git
        else
            safe_exit "Package manager not supported. Please install git manually."
        fi
    fi

    if ! command -v curl &> /dev/null; then
        log_message "i" "curl is not installed. Installing curl..." "$BLUE"
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy curl
        else
            safe_exit "Package manager not supported. Please install curl manually."
        fi
    fi
}

# Function to backup files with progress indication
backup_files() {
    log_message "i" "Creating backup directory: ${BACKUP_DIR}" "$BLUE"
    mkdir -p "${BACKUP_DIR}" || safe_exit "Could not create backup directory"

    log_message "i" "Cloning dotfiles repository..." "$BLUE"
    execute_command "git clone --depth=1 \"${DOTFILES_REPO}\" \"${TEMP_DIR}\"" "Cloning dotfiles repository..."

    log_message "i" "Backing up existing files..." "$BLUE"
    while IFS= read -r -d '' file; do
        relative_path="${file#"${TEMP_DIR}/"}"
        target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
        mkdir -p "${target_dir}"
        if [ -e "${HOME}/${relative_path}" ]; then
            log_message "i" "Backing up: ${HOME}/${relative_path}" "$BLUE"
            mv "${HOME}/${relative_path}" "${target_dir}/" || safe_exit "Failed to backup ${relative_path}"
        fi
    done < <(find "${TEMP_DIR}" -type f -print0)

    rm -rf "${TEMP_DIR}"
}

# Function to initialize and checkout dotfiles
initialize_and_checkout_dotfiles() {
    if [ -d "${DOTDIR}" ]; then
        execute_command "mv \"${DOTDIR}\" \"${BACKUP_DIR}/\"" "Moving existing ${DOTDIR} to backup directory..."
    fi
    execute_command "git clone --bare \"${DOTFILES_REPO}\" \"${DOTDIR}\"" "Cloning bare repository..."
    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" config --local status.showUntrackedFiles no" "Configuring dotfiles..."

    log_message "i" "Removing old dotfiles in the home directory..." "$BLUE"
    execute_command "rm -rf \$(find ${HOME} -maxdepth 1 -type f)" "Removing old dotfiles..."

    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" checkout" "Checking out dotfiles..."
}

# Prompt user for confirmation, handle non-interactive shell
prompt_user() {
    if [ -t 1 ]; then
        read -p "[?] Do you want to continue with the deployment? [y/N]: " choice
        case "$choice" in
            y|Y ) log_message "i" "User chose to continue." "$BLUE";;
            * ) safe_exit "Deployment aborted by user.";;
        esac
    else
        log_message "i" "Non-interactive shell detected. Proceeding without user prompt." "$BLUE"
    fi
}

# Function to handle repeated script execution
handle_repeated_execution() {
    if [ -d "${BACKUP_DIR}" ]; then
        log_message "!" "Backup directory already exists. Previous backup will be overwritten." "$YELLOW"
    fi
    if [ -d "${DOTDIR}" ]; then
        log_message "!" "Dotfiles directory already exists. It will be moved to the backup directory." "$YELLOW"
    fi
}

# Main script execution starts here
main() {
    trap 'rm -f /tmp/deploy.sh' EXIT
    log_message "i" "Starting deployment script..." "$BLUE"
    install_dependencies
    prompt_user
    handle_repeated_execution
    backup_files
    initialize_and_checkout_dotfiles
    log_message "✔ Success" "Deployment completed successfully." "$GREEN"
}

main "$@"
