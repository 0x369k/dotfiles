#!/usr/bin/env bash
# Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default configuration
declare -A CONFIG
CONFIG=(
    [DOTFILES_REPO]="https://github.com/0x369k/dotfiles.git"
    [DOTDIR]="${HOME}/.dotfiles"
    [BACKUP_DIR]="${HOME}/.dotfiles_backup"
    [LOG_DIR]="${HOME}/.dotfiles_log"
    [DOCKERFILE_URL]="https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/Dockerfile"
    [DOCKER_COMPOSE_FILE_URL]="https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml"
)

# Load user configuration if available
CONFIG_FILE="${HOME}/.dotfiles.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Repositories and file URLs
DOTFILES_REPO="${CONFIG[DOTFILES_REPO]}"
DOTDIR="${CONFIG[DOTDIR]}"
BACKUP_DIR="${CONFIG[BACKUP_DIR]}/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"
LOG_DIR="${CONFIG[LOG_DIR]}"
LOG_FILE="${LOG_DIR}/deploy_$(date +%Y-%m-%d_%H-%M-%S).log"
DOCKERFILE_URL="${CONFIG[DOCKERFILE_URL]}"
DOCKER_COMPOSE_FILE_URL="${CONFIG[DOCKER_COMPOSE_FILE_URL]}"

# Setup Cleanup Trap
cleanup() {
    echo "Running Cleanup..."
    # Beispiel: Löschen des temporären Verzeichnisses
    [[ -d "${TEMP_DIR}" ]] && rm -rf "${TEMP_DIR}"
    echo "Cleanup completed."
}
trap cleanup EXIT

log_message() {
    local message="$1"
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

safe_exit() {
    local message="$1"
    local code="${2:-1}" # Default exit status 1
    echo -e "\033[38;5;160m▓▒░ \033[38;5;196mError: \033[38;5;160m${message}\033[0m\n" | tee -a "$LOG_FILE"
    exit "$code"
}

execute_command() {
    local command="$1"
    local message="$2"
    local ignore_error="${3:-false}"
    echo -e "\033[38;5;33m▓▒░ \033[38;5;39mExecuting: \033[38;5;33m${message}\033[0m\n"
    log_message "[i] $message"
    if $ignore_error; then
        eval "$command" 2>>"$LOG_FILE" || true
    else
        eval "$command" 2>>"$LOG_FILE" || {
            log_message "Failed to execute: $command"
            return 1
        }
    fi
}

download_file() {
    local url="$1"
    local target_file="$2"
    local message="$3"
    local max_attempts=3
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        execute_command "curl -fLks '$url' -o '$target_file'" "$message" true
        if [ $? -eq 0 ]; then
            break
        else
            log_message "[!] Failed to download $url (attempt $attempt/$max_attempts)"
            attempt=$((attempt + 1))
            sleep 2
        fi
    done
    if [ $attempt -gt $max_attempts ]; then
        safe_exit "Failed to download $url after $max_attempts attempts" 2
    fi
}

download_deploy_script() {
    local deploy_script_url="https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh"
    local deploy_script_path="/tmp/deploy.sh"
    download_file "$deploy_script_url" "$deploy_script_path" "Downloading deploy.sh script..."
    chmod +x "$deploy_script_path"
    echo "$deploy_script_path"
}

backup_files() {
    log_message "[i] Creating backup directory: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}" || safe_exit "Could not create backup directory"
    log_message "[i] Cloning dotfiles repository..."
    execute_command "git clone --depth=1 \"${DOTFILES_REPO}\" \"${TEMP_DIR}\"" "Cloning dotfiles repository..."
    while IFS= read -r -d '' file; do
        relative_path="${file#"${TEMP_DIR}/"}"
        target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
        mkdir -p "${target_dir}"
        if [ -e "${HOME}/${relative_path}" ]; then
            echo -e "\033[38;5;220m▓▒░ \033[38;5;11mBacking up: \033[38;5;220m${HOME}/${relative_path}\033[0m\n"
            log_message "[i] Backing up: ${HOME}/${relative_path}"
            mv "${HOME}/${relative_path}" "${target_dir}/"
        fi
    done < <(find "${TEMP_DIR}" -type f -print0)
    for dir in ".zi"; do
        if [ -d "${HOME}/${dir}" ]; then
            echo -e "\033[38;5;220m▓▒░ \033[38;5;11mBacking up directory: \033[38;5;220m${HOME}/${dir}\033[0m\n"
            log_message "[i] Backing up directory: ${HOME}/${dir}"
            mv "${HOME}/${dir}" "${BACKUP_DIR}/"
        fi
    done
    for file in ".zshrc" ".zshenv" ".zprofile" ".zlogin" ".zlogout" ".zsh_history"; do
        if [ -e "${HOME}/${file}" ]; then
            echo -e "\033[38;5;220m▓▒░ \033[38;5;11mBacking up file: \033[38;5;220m${HOME}/${file}\033[0m\n"
            log_message "[i] Backing up file: ${HOME}/${file}"
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

create_docker_container() {
    local workdir="$1"
    if [ -z "$workdir" ]; then
        workdir="${HOME}/docker_workbench"
        mkdir -p "$workdir"
    fi
    if docker ps -a --format '{{.Names}}' | grep -Eq "^dotfiles-container$"; then
        echo -e "\033[38;5;220m▓▒░ \033[38;5;11mContainer already exists. \033[38;5;220mRecreating...\033[0m\n"
        log_message "[i] Container already exists. Recreating..."
        docker rm -f dotfiles-container
    fi
    # Download required files if not available locally
    if [ ! -f "${HOME}/.devcontainer/Dockerfile" ]; then
        download_file "${DOCKERFILE_URL}" "${HOME}/.devcontainer/Dockerfile" "Downloading Dockerfile..."
    fi
    if [ ! -f "${HOME}/.devcontainer/docker-compose.yml" ]; then
        download_file "${DOCKER_COMPOSE_FILE_URL}" "${HOME}/.devcontainer/docker-compose.yml" "Downloading docker-compose.yml..."
    fi
    execute_command "docker build -t dotfiles-image -f ${HOME}/.devcontainer/Dockerfile ." "Building Docker image..."
    execute_command "docker run -d --name dotfiles-container -v ${workdir}:/home/${USERNAME:-developer}/workspace dotfiles-image" "Creating Docker container..."
    execute_command "docker cp ${LOG_DIR} dotfiles-container:/home/${USERNAME:-developer}/" "Copying log directory to container..."
}

display_ascii_art() {
    echo -e "
\033[38;5;33m ____ __ ______ __
 / __ \\____ / /_/ ____// /__ _____
 / / / / __ \\/ __/ /_ / / _ \\/ ___/
 / /_/ / /_/ / /_/ __/ / / __(__ )
/_____/\\____/\\__/_/ /_/\\___/____/
\033[38;5;39m ___ __
 / \\___ ____ / /___ __ __
 / /\\ / _ \\/ __ \\/ / __ \\/ / / /
 / /_// (_) / /_/ / / /_/ / /_/ /
/___,' \\___/ .___/_/\\____/\\__, /
 /_/ /____/
\033[0m
"
}

display_success_message() {
    echo -e "
\033[38;5;46m▓▒░ \033[38;5;49mDotfiles deployed successfully!\033[0m
Deployment details:
- Dotfiles repository: \033[38;5;39m${DOTFILES_REPO}\033[0m
- Backup directory: \033[38;5;39m${BACKUP_DIR}\033[0m
- Log file: \033[38;5;39m${LOG_FILE}\033[0m
Thank you for using the Dotfiles Deployment Script!
"
}

main() {
    local mode="$1"
    local selective_deployment="${2:-false}"
    local restore_dir="$3"

if [[ "$mode" != "--docker" ]]; then
    echo "Das Deployment-Skript kann nur mit dem Argument --docker ausgeführt werden."
exit 1
fi

    mkdir -p "${LOG_DIR}"
    log_message "[i] Starting deployment script in mode: ${mode}"
    display_ascii_art
    case "$mode" in
    "--local")
        backup_files
        if [[ "$selective_deployment" == "--selective" ]]; then
            echo -e "\033[38;5;33m▓▒░ \033[38;5;39mPerforming selective deployment.\033[0m\n"
            log_message "[i] Performing selective deployment."
        # Implement selective deployment logic here
        else
            initialize_and_checkout_dotfiles
        fi
        ;;
    "--docker")
        local workdir="$2"
        create_docker_container "$workdir"
        # Nachdem der Container-Prozess abgeschlossen ist, starte eine interaktive Bash-Shell
        # Dies ist nur relevant, wenn das Skript innerhalb eines Docker-Containers ausgeführt wird
        echo "Starten einer interaktiven Bash-Shell für Docker..."
        exec bash
        ;;
    "--restore")
        restore_dotfiles "$restore_dir"
        ;;
    *)
        safe_exit "Invalid mode. Usage: deploy.sh [--local|--docker [workdir]|--restore [backup_dir]]" 1
        ;;
    esac
    # Wenn das Skript nicht im Docker-Modus läuft, können Sie entscheiden, ob hier ebenfalls eine Shell gestartet werden soll.
    if [[ "$mode" != "--docker" ]]; then
        echo "Deployment abgeschlossen. Öffne interaktive Shell..."
        exec bash
    fi
    display_success_message
    log_message "[✔] Deployment completed successfully."
}

# Herunterladen des deploy.sh-Skripts, wenn es nicht lokal vorhanden ist
if [ "$0" = "bash" ] || [ "$0" = "/bin/bash" ]; then
deploy_script_path=$(download_deploy_script)
exec "$deploy_script_path" "$@"
else
main "$@"
fi
