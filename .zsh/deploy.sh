#!/usr/bin/env bash

set -e  # Abbruch bei Fehlern
set -u  # Abbruch bei Verwendung nicht definierter Variablen

# Farbdefinitionen
GREEN='\\033[0;32m'
RED='\\033[0;31m'
YELLOW='\\033[0;33m'
NC='\\033[0m' # No color
BOLD='\\033[1m'
NORMAL='\\033[0m'

# Standardkonfigurationswerte
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"
LOG_DIR="${HOME}/.dotfiles_log"
LOG_FILE="${LOG_DIR}/deploy_$(date +%Y-%m-%d_%H-%M-%S).log"
CONTAINER_NAME="dotfiles-container"

# Initialize mode variables
DOCKER_MODE=false
LOCAL_MODE=false

# Protokollierungsfunktion für allgemeine Nachrichten
log_message() {
    local status="$1"
    local message="$2"
    local color="${3:-$NC}"
    echo -e "${color}${status}${NC} ${message}" | tee -a "$LOG_FILE"
}

# Fehlerbehandlung und Abbruchfunktion
safe_exit() {
    local message="$1"
    local code="${2:-1}" # Standard-Exit-Status 1
    log_message "✘" "$message" "$RED"
    exit "$code"
}

# Befehlsausführung mit Protokollierung
execute_command() {
    local command="$1"
    local message="$2"
    local ignore_error="${3:-false}"

    log_message "i" "$message" "$YELLOW"
    if $ignore_error; then
        eval "$command" 2>>"$LOG_FILE" && log_message "✔" "$message abgeschlossen." "$GREEN" || {
            log_message "✘" "$message fehlgeschlagen." "$RED"
            true
        }
    else
        eval "$command" 2>>"$LOG_FILE" && log_message "✔" "$message abgeschlossen." "$GREEN" || safe_exit "$message fehlgeschlagen."
    fi
}

# Sicherungsfunktion für Dateien und Verzeichnisse
backup_files() {
    log_message "i" "Erstellen des Backup-Verzeichnisses: ${BOLD}${BACKUP_DIR}${NORMAL}" "$YELLOW"
    mkdir -p "${BACKUP_DIR}" || safe_exit "Konnte das Backup-Verzeichnis nicht erstellen"

    log_message "i" "Klone das Dotfiles-Repository..." "$YELLOW"
    execute_command "git clone --depth=1 \\"${DOTFILES_REPO}\\" \\"${TEMP_DIR}\\"" "Klone das Dotfiles-Repository" || safe_exit "Klone das Dotfiles-Repository fehlgeschlagen"
    log_message "i" "Sichern vorhandener Dateien..." "$YELLOW"
    find "${TEMP_DIR}" -type f -print0 | while IFS= read -r -d '' file; do
        relative_path="${file#"${TEMP_DIR}/"}"
        target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
        mkdir -p "${target_dir}"
        if [ -e "${HOME}/${relative_path}" ]; then
            if mv "${HOME}/${relative_path}" "${target_dir}/"; then
                log_message "✔" "Gesichert: ${BOLD}${HOME}/${relative_path}${NORMAL} nach ${BOLD}${target_dir}/${relative_path}${NORMAL}" "$GREEN"
            else
                log_message "✘" "Sicherung fehlgeschlagen: ${relative_path}" "$RED"
            fi
        fi
    done
    rm -rf "${TEMP_DIR}"
}

# Dummy install_dependencies function
install_dependencies() {
    log_message "i" "Installiere Abhängigkeiten (Dummy-Funktion)" "$YELLOW"
    # Simulate installation
    sleep 1
    log_message "✔" "Abhängigkeiten erfolgreich installiert (Dummy)" "$GREEN"
}

# Dummy prompt_user function
prompt_user() {
    log_message "i" "Benutzereingabe anfordern (Dummy-Funktion)" "$YELLOW"
    # Simulate user prompt
    sleep 1
    log_message "✔" "Benutzereingabe abgeschlossen (Dummy)" "$GREEN"
}

# Dummy handle_repeated_execution function
handle_repeated_execution() {
    log_message "i" "Überprüfen auf wiederholte Ausführung (Dummy-Funktion)" "$YELLOW"
    # Simulate checking for repeated execution
    sleep 1
    log_message "✔" "Überprüfung auf wiederholte Ausführung abgeschlossen (Dummy)" "$GREEN"
}

# Initialisieren und Auschecken der Dotfiles
initialize_and_checkout_dotfiles() {
    if [ -d "${DOTDIR}" ]; then
        execute_command "mv \\"${DOTDIR}\\" \\"${BACKUP_DIR}/\\"" "Verschieben des vorhandenen ${DOTDIR} in das Backup-Verzeichnis"
    fi
    execute_command "git clone --bare \\"${DOTFILES_REPO}\\" \\"${DOTDIR}\\"" "Klone das Bare-Repository"
    execute_command "git --git-dir=\\"${DOTDIR}\\" --work-tree=\\"${HOME}\\" config --local status.showUntrackedFiles no" "Konfiguriere Dotfiles"
    execute_command "git --git-dir=\\"${DOTDIR}\\" --work-tree=\\"${HOME}\\" checkout" "Checke Dotfiles aus"
}

# Ausführen des Skripts innerhalb eines Docker-Containers
run_in_docker() {
    local docker_workspace="${1:-${HOME}/docker_workspace}"

    # Docker-Container erstellen und ausführen
    echo "Simulating Docker run with workspace: ${docker_workspace}"
    execute_command "mkdir -p ${docker_workspace}" "Erstellen des Docker-Arbeitsverzeichnisses"
    execute_command "echo \\"Docker container running...\\" > ${docker_workspace}/docker_simulation.log" "Simulieren der Docker-Ausführung"
}

# Argumente parsen
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --docker)
                DOCKER_MODE=true
                if [ -n "${2:-}" ] && [[ "$2" != --* ]]; then
                    DOCKER_WORKSPACE="$2"
                    shift 2
                else
                    DOCKER_WORKSPACE="${HOME}/docker_workspace"
                    shift
                fi
                ;;
            --local)
                LOCAL_MODE=true
                shift
                ;;
            --help)
                echo "Usage: $0 [--docker [PATH]] [--local] [--help]"
                exit 0
                ;;
            *)
                echo "Unknown parameter: $1"
                exit 1
                ;;
        esac
    done
}

# Hauptskript-Ausführung
main() {
    parse_args "$@"
    mkdir -p "${LOG_DIR}"
    mkdir -p "${TEMP_DIR}"  # Ensure TEMP_DIR exists
    log_message "i" "Starting deployment script in mode: ${DOCKER_MODE:+docker}${LOCAL_MODE:+local}"
    if [ "$DOCKER_MODE" = true ]; then
        run_in_docker "$DOCKER_WORKSPACE"
    elif [ "$LOCAL_MODE" = true ]; then
        install_dependencies
        prompt_user
        handle_repeated_execution
        backup_files
        initialize_and_checkout_dotfiles
        log_message "✔" "Deployment erfolgreich abgeschlossen." "$GREEN"
    else
        echo "Unbekannter Ausführungsmodus. Verwenden Sie --docker oder --local."
        exit 1
    fi
}

main "$@"