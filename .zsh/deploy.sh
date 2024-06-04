#!/usr/bin/env bash

# Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repositories und Dateipfade
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"
LOG_FILE="/tmp/deploy.log"
SCRIPT_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh"
DOWNLOAD_TEMP_DIR="/tmp/dotfiles_download"
AUTO_CONFIRM=false

# Protokollierung
log_message() {
    local status="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}[${status}] ${message}${NC}" | tee -a "$LOG_FILE"
}

# Sicheres Beenden mit Fehlerprotokollierung
safe_exit() {
    local message="$1"
    local code="${2:-1}" # Standard-Exit-Status 1
    log_message "✘ Error" "$message" "$RED"
    [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
    exit "$code"
}

# Verbesserte Fehlerbehandlung
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


# Funktion zum Sichern von Dateien
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
        if [ -e "${HOME}/${relative_path}" ];then
            log_message "i" "Backing up: ${HOME}/${relative_path}" "$BLUE"
            mv "${HOME}/${relative_path}" "${target_dir}/" || safe_exit "Failed to backup ${relative_path}"
        fi
    done < <(find "${TEMP_DIR}" -type f -print0)

    rm -rf "${TEMP_DIR}"
}

# Funktion zum initialisieren und auschecken von dotfiles
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

# Benutzerabfrage
prompt_user() {
    if [ -t 1 ]; then
        read -p "[?] Do you want to continue with the deployment? [y/N]: " choice
        case "$choice" in
            y|Y ) log_message "i" "User chose to continue." "$BLUE";;
            * ) safe_exit "Deployment aborted by user.";;
        esac
    else
        log_message "i" "Non-interactive shell detected. Proceeding without user prompt." "$BLUE"
        AUTO_CONFIRM=true
    fi
}

# Behandlung wiederholter Skriptausführung
handle_repeated_execution() {
    if [ -d "${BACKUP_DIR}" ]; then
        log_message "!" "Backup directory already exists. Previous backup will be overwritten." "$YELLOW"
    fi
    if [ -d "${DOTDIR}" ]; then
        log_message "!" "Dotfiles directory already exists. It will be moved to the backup directory." "$YELLOW"
    fi
}

# Hauptsache des Skripts
main() {
    log_message "i" "Starting deployment script..." "$BLUE"

    # Überprüfen, ob das Skript bereits ausgeführt wird
    if [ "${BASH_SOURCE[0]}" != "$0" ]; then
        # Das Skript wird erneut ausgeführt
        install_dependencies
        prompt_user
        handle_repeated_execution
        backup_files
        initialize_and_checkout_dotfiles
        log_message "✔ Success" "Deployment completed successfully." "$GREEN"
    else
        # Das Skript wird zum ersten Mal ausgeführt
        mkdir -p "${DOWNLOAD_TEMP_DIR}"
        execute_command
        mkdir -p "${DOWNLOAD_TEMP_DIR}"
        execute_command "curl -Lks '${SCRIPT_URL}' -o '${DOWNLOAD_TEMP_DIR}/deploy.sh'" "Downloading deployment script..."

        # Skript erneut ausführen
        chmod +x "${DOWNLOAD_TEMP_DIR}/deploy.sh"
        "${DOWNLOAD_TEMP_DIR}/deploy.sh"
        rm -rf "${DOWNLOAD_TEMP_DIR}"
    fi
}

# Hauptskript-Ausführung aufrufen
main "$@"