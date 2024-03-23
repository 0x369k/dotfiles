#!/usr/bin/env zsh

# Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default configuration
typeset -A CONFIG
CONFIG=(
    DOTFILES_REPO "https://github.com/0x369k/dotfiles.git"
    DOTDIR "${HOME}/.dotfiles"
    BACKUP_DIR "${HOME}/.dotfiles_backup"
    LOG_DIR "${HOME}/.dotfiles_log"
    DOCKERFILE_URL "https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/Dockerfile"
    DOCKER_COMPOSE_FILE_URL "https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/docker-compose.yml"
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

log_message() {
    local message="$1"
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

safe_exit() {
    local message="$1"
    local code="${2:-1}" # Default exit status 1
    print -P "%F{160}▓▒░ %F{196}Error: %F{160}${message}%f%b\n" | tee -a "$LOG_FILE"
    [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
    exit "$code"
}

execute_command() {
    local command="$1"
    local message="$2"
    local ignore_error="${3:-false}"
    print -P "%F{33}▓▒░ %F{39}Executing: %F{33}${message}%f%b\n"
    log_message "[i] $message"
    if $ignore_error; then
        eval "$command" 2>>"$LOG_FILE" || true
    else
        eval "$command" 2>>"$LOG_FILE" || safe_exit "Failed to execute: $command" 2
    fi
}

download_file() {
    local url="$1"
    local target_file="$2"
    local message="$3"
    execute_command "curl -Lks '$url' -o '$target_file'" "$message"
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
            print -P "%F{220}▓▒░ %F{11}Backing up: %F{220}${HOME}/${relative_path}%f%b\n"
            log_message "[i] Backing up: ${HOME}/${relative_path}"
            mv "${HOME}/${relative_path}" "${target_dir}/"
        fi
    done < <(find "${TEMP_DIR}" -type f -print0)
    
    for dir in ".zi"; do
        if [ -d "${HOME}/${dir}" ]; then
            print -P "%F{220}▓▒░ %F{11}Backing up directory: %F{220}${HOME}/${dir}%f%b\n"
            log_message "[i] Backing up directory: ${HOME}/${dir}"
            mv "${HOME}/${dir}" "${BACKUP_DIR}/"
        fi
    done
    
    for file in ".zshrc" ".zshenv" ".zprofile" ".zlogin" ".zlogout" ".zsh_history"; do
        if [ -e "${HOME}/${file}" ]; then
            print -P "%F{220}▓▒░ %F{11}Backing up file: %F{220}${HOME}/${file}%f%b\n"
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
        print -P "%F{220}▓▒░ %F{11}Container already exists. %F{220}Recreating...%f%b\n"
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
    execute_command "docker run -d --name dotfiles-container -v ${workdir}:/home/dotfiles/workspace dotfiles-image" "Creating Docker container..."
    
    execute_command "docker cp ${LOG_DIR} dotfiles-container:/home/dotfiles/" "Copying log directory to container..."
    execute_command "docker exec dotfiles-container rm -rf /home/dotfiles/.dotfiles_log && mv /home/dotfiles/$(basename ${LOG_DIR}) /home/dotfiles/.dotfiles_log" "Moving log directory inside container..."
    
    rm -rf "${LOG_DIR}"
}

display_ascii_art() {
    print -P "
%F{33}    ____        __  ______ __           
   / __ \____  / /_/ ____// /__  _____  
  / / / / __ \/ __/ /_   / / _ \/ ___/  
 / /_/ / /_/ / /_/ __/  / /  __(__  )   
/_____/\____/\__/_/    /_/\___/____/    
                                        
%F{39}    ___             __           
   /   \___  ____  / /___  __  __
  / /\ / _ \/ __ \/ / __ \/ / / /
 / /_// (_) / /_/ / / /_/ / /_/ / 
/___,' \___/ .___/_/\____/\__, /  
          /_/            /____/   
%f%b
"
}

display_success_message() {
    print -P "
%F{46}▓▒░ %F{49}Dotfiles deployed successfully!%f%b

Deployment details:
- Dotfiles repository: %F{39}${DOTFILES_REPO}%f%b
- Backup directory: %F{39}${BACKUP_DIR}%f%b
- Log file: %F{39}${LOG_FILE}%f%b

Thank you for using the Dotfiles Deployment Script!
"
}

main() {
    local mode="$1"
    local selective_deployment="${2:-false}"
    local restore_dir="$3"
    
    if [[ "$mode" == "--interactive" ]]; then
        interactive_mode
        exit 0
    fi
    
    mkdir -p "${LOG_DIR}"
    log_message "[i] Starting deployment script in mode: ${mode}"
    
    display_ascii_art
    
    case "$mode" in
        "--local")
            backup_files
            if [[ "$selective_deployment" == "--selective" ]]; then
                print -P "%F{33}▓▒░ %F{39}Performing selective deployment.%f%b\n"
                log_message "[i] Performing selective deployment."
                # Implement selective deployment logic here
            else
                initialize_and_checkout_dotfiles
            fi
            ;;
        "--docker")
            local workdir="$2"
            create_docker_container "$workdir"
            ;;
        "--restore")
            restore_dotfiles "$restore_dir"
            ;;
        *)
            safe_exit "Invalid mode. Usage: deploy.sh [--local|--docker [workdir]|--restore [backup_dir]|--interactive]" 1
            ;;
    esac
    
    display_success_message
    log_message "[✔] Deployment completed successfully."
}

main "$@"