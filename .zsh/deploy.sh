#!/usr/bin/env bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color
BOLD='\033[1m'
NORMAL='\033[0m'

# Default configuration values
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR=$(mktemp -d -t dotfiles_temp-XXXXXXXXXX)
LOG_FILE=$(mktemp -t deploy.log-XXXXXXXXXX)
WORKSPACE_DIR="/home/developer"
INTERACTIVE=false
DOCKER_MODE=false
DOCKER_WORKSPACE=""
CONTAINER_NAME="zsh_dev_container"

# Logging function for general messages
log_message() {
    local status="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}${status}${NC} ${message}" | tee -a "$LOG_FILE"
}

# Improved safe_exit function with error logging
safe_exit() {
    local message="$1"
    local code="${2:-1}" # Default exit status 1
    log_message "✘" "$message" "$RED"
    exit "$code"
}

# Improved error handling
execute_command() {
    local command="$1"
    local message="$2"
    local ignore_error="${3:-false}"

    log_message "i" "$message" "$YELLOW"

    if $ignore_error; then
        eval "$command" 2>>"$LOG_FILE" && log_message "✔" "$message completed." "$GREEN" || {
            log_message "✘" "$message failed." "$RED"
            true
        }
    else
        eval "$command" 2>>"$LOG_FILE" && log_message "✔" "$message completed." "$GREEN" || safe_exit "$message failed."
    fi
}

# Function to check and install dependencies
install_dependencies() {
    log_message "i" "Checking required dependencies..." "$YELLOW"
    for dep in git curl; do
        if ! command -v "$dep" &> /dev/null; then
            log_message "i" "${BOLD}$dep${NORMAL} is not installed. Installing ${BOLD}$dep${NORMAL}..." "$YELLOW"
            install_package "$dep"
        else
            log_message "✔" "${BOLD}$dep${NORMAL} is already installed." "$GREEN"
        fi
    done
}

# Function to install a package based on the available package manager
install_package() {
    local package="$1"
    if command -v apt-get &> /dev/null; then
        execute_command "sudo apt-get update && sudo apt-get install -y $package" "Installing $package"
    elif command -v yum &> /dev/null; then
        execute_command "sudo yum install -y $package" "Installing $package"
    elif command -v pacman &> /dev/null; then
        execute_command "sudo pacman -Sy $package" "Installing $package"
    elif command -v dnf &> /dev/null; then
        execute_command "sudo dnf install -y $package" "Installing $package"
    elif command -v brew &> /dev/null; then
        execute_command "brew install $package" "Installing $package"
    elif command -v zypper &> /dev/null; then
        execute_command "sudo zypper install -y $package" "Installing $package"
    else
        safe_exit "Unsupported package manager. Please install $package manually."
    fi
}

# Function to show a progress bar
show_progress() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep -w $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to back up files with success/failure indication
backup_files() {
    log_message "i" "Creating backup directory: ${BOLD}${BACKUP_DIR}${NORMAL}" "$YELLOW"
    mkdir -p "${BACKUP_DIR}" || safe_exit "Could not create backup directory"

    log_message "i" "Cloning dotfiles repository..." "$YELLOW"
    execute_command "git clone --depth=1 \"${DOTFILES_REPO}\" \"${TEMP_DIR}\"" "Cloning dotfiles repository"

    log_message "i" "Backing up existing files..." "$YELLOW"
    ( find "${TEMP_DIR}" -type f -print0 | while IFS= read -r -d '' file; do
        relative_path="${file#"${TEMP_DIR}/"}"
        target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
        mkdir -p "${target_dir}"
        if [ -e "${HOME}/${relative_path}" ]; then
            if mv "${HOME}/${relative_path}" "${target_dir}/"; then
                log_message "✔" "Backed up: ${BOLD}${HOME}/${relative_path}${NORMAL} to ${BOLD}${target_dir}/${relative_path}${NORMAL}" "$GREEN"
            else
                log_message "✘" "Failed to back up ${relative_path}" "$RED"
            fi
        fi
    done ) &
    show_progress
    rm -rf "${TEMP_DIR}"
}

# Function to initialize and check out dotfiles
initialize_and_checkout_dotfiles() {
    if [ -d "${DOTDIR}" ]; then
        execute_command "mv \"${DOTDIR}\" \"${BACKUP_DIR}/\"" "Moving existing ${DOTDIR} to backup directory"
    fi
    execute_command "git clone --bare \"${DOTFILES_REPO}\" \"${DOTDIR}\"" "Cloning bare repository"
    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" config --local status.showUntrackedFiles no" "Configuring dotfiles"

    log_message "i" "Removing old dotfiles in home directory..." "$YELLOW"
    find "${HOME}" -maxdepth 1 -type f -exec rm -rf {} \; || safe_exit "Failed to remove old dotfiles"

    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" checkout" "Checking out dotfiles"
}

# Function to run the script inside a Docker container
# Function to run the script inside a Docker container
run_in_docker() {
    local docker_workspace="${1:-/home/developer}"

    # Pull the Docker image and run the container
    docker run --rm --name ${CONTAINER_NAME} -v "${PWD}:${docker_workspace}" -w "${docker_workspace}" -u developer archlinux:latest bash -c "\
        sudo pacman -Syu --noconfirm --needed && \
        sudo pacman -S --noconfirm --needed git curl && \
        curl -fsSL https://github.com/0x369k/dotfiles/raw/main/.zsh/deploy.sh | bash -s"
}

# Function to parse arguments
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --docker)
                DOCKER_MODE=true
                if [ -n "$2" ] && [[ "$2" != --* ]]; then
                    DOCKER_WORKSPACE="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --workspace)
                WORKSPACE_DIR="$2"
                shift 2
                ;;
            --repo)
                DOTFILES_REPO="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--docker [PATH]] [--workspace DIR] [--repo REPO_URL]"
                exit 0
                ;;
            *)
                echo "Unknown parameter: $1"
                exit 1
                ;;
        esac
    done
}

# Prompt user for confirmation, consider non-interactive shell
prompt_user() {
    if [ "${INTERACTIVE}" = true ]; then
        echo -e "${YELLOW}The following actions will be performed:${NC}"
        echo -e "${YELLOW}1. Backing up existing files to ${BACKUP_DIR}.${NC}"
        echo -e "${YELLOW}2. Cloning the dotfiles repository into a temporary directory.${NC}"
        echo -e "${YELLOW}3. Moving existing dotfiles to ${BACKUP_DIR}.${NC}"
        echo -e "${YELLOW}4. Cloning the bare repository into ${DOTDIR}.${NC}"
        echo -e "${YELLOW}5. Configuring and checking out the dotfiles into the home directory.${NC}"
        echo -e "${YELLOW}6. Checking and installing dependencies (git, curl).${NC}"
        
        read -p "$(echo -e ${YELLOW}? Do you want to proceed with the deployment? [y/N]: ${NC})" choice
        case "$choice" in
            y|Y ) 
                log_message "i" "User consented." "$YELLOW"
                ;;
            * ) safe_exit "Deployment aborted by user.";;
        esac
    else
        log_message "i" "Non-interactive shell detected. Proceeding without user prompt." "$YELLOW"
    fi
}

# Function to check if the script is already running
handle_repeated_execution() {
    if [ -f "$LOG_FILE" ]; then
        log_message "i" "The script appears to be already running. Skipping redundant steps." "$YELLOW"
        return
    fi
}

# Main script execution starts here
main() {
    parse_args "$@"
    if [ "$DOCKER_MODE" = true ]; then
        run_in_docker "$DOCKER_WORKSPACE"
    else
        install_dependencies
        prompt_user
        handle_repeated_execution
        backup_files
        initialize_and_checkout_dotfiles
        log_message "✔" "Deployment successfully completed." "$GREEN"
    fi
}

main "$@"
