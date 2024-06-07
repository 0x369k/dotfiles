#!/usr/bin/env bash

# Farbcodes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # Keine Farbe
BOLD='\033[1m'
NORMAL='\033[0m'

# Standardwerte für Konfigurationen
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"
LOG_FILE="/tmp/deploy.log"
WORKSPACE_DIR="${HOME}"

# Protokollierungsfunktion für allgemeine Nachrichten
log_message() {
    local status="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}${status}${NC} ${message}" | tee -a "$LOG_FILE"
}

# Exit-Trap-Funktion zum Aufräumen
cleanup() {
    log_message "i" "Bereinige temporäre Dateien..." "$YELLOW"
    [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# Verbesserte safe_exit Funktion mit Fehlerprotokollierung
safe_exit() {
    local message="$1"
    local code="${2:-1}" # Standard Exit-Status 1
    log_message "✘" "$message" "$RED"
    exit "$code"
}

# Verbesserte Fehlerbehandlung
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

# Funktion zum Überprüfen und Installieren von Abhängigkeiten
install_dependencies() {
    log_message "i" "Überprüfe erforderliche Abhängigkeiten..." "$YELLOW"
    for dep in git curl; do
        if ! command -v "$dep" &> /dev/null; then
            log_message "i" "${BOLD}$dep${NORMAL} ist nicht installiert. Installiere ${BOLD}$dep${NORMAL}..." "$YELLOW"
            install_package "$dep"
        else
            log_message "✔" "${BOLD}$dep${NORMAL} ist bereits installiert." "$GREEN"
        fi
    done
}

# Funktion zum Installieren eines Pakets basierend auf dem verfügbaren Paketmanager
install_package() {
    local package="$1"
    if command -v apt-get &> /dev/null; then
        execute_command "sudo apt-get update && sudo apt-get install -y $package" "Installiere $package"
    elif command -v yum &> /dev/null; then
        execute_command "sudo yum install -y $package" "Installiere $package"
    elif command -v pacman &> /dev/null; then
        execute_command "sudo pacman -Sy $package" "Installiere $package"
    else
        safe_exit "Paketmanager nicht unterstützt. Bitte installiere $package manuell."
    fi
}

# Funktion zur Anzeige eines Fortschrittsbalkens
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

# Funktion zum Sichern von Dateien mit Erfolgs-/Fehleranzeige
backup_files() {
    log_message "i" "Erstelle Backup-Verzeichnis: ${BOLD}${BACKUP_DIR}${NORMAL}" "$YELLOW"
    mkdir -p "${BACKUP_DIR}" || safe_exit "Konnte Backup-Verzeichnis nicht erstellen"

    log_message "i" "Klone Dotfiles Repository..." "$YELLOW"
    execute_command "git clone --depth=1 \"${DOTFILES_REPO}\" \"${TEMP_DIR}\"" "Klone Dotfiles Repository"

    log_message "i" "Sichere bestehende Dateien..." "$YELLOW"
    ( find "${TEMP_DIR}" -type f -print0 | while IFS= read -r -d '' file; do
        relative_path="${file#"${TEMP_DIR}/"}"
        target_dir="${BACKUP_DIR}/$(dirname "${relative_path}")"
        mkdir -p "${target_dir}"
        if [ -e "${WORKSPACE_DIR}/${relative_path}" ]; then
            if mv "${WORKSPACE_DIR}/${relative_path}" "${target_dir}/"; then
                log_message "✔" "Sichere: ${BOLD}${WORKSPACE_DIR}/${relative_path}${NORMAL} nach ${BOLD}${target_dir}/${relative_path}${NORMAL}" "$GREEN"
            else
                log_message "✘" "Sichern von ${relative_path} fehlgeschlagen" "$RED"
            fi
        fi
    done ) &
    show_progress
    rm -rf "${TEMP_DIR}"
}

# Funktion zum Initialisieren und Auschecken der Dotfiles
initialize_and_checkout_dotfiles() {
    if [ -d "${DOTDIR}" ]; then
        execute_command "mv \"${DOTDIR}\" \"${BACKUP_DIR}/\"" "Verschiebe bestehendes ${DOTDIR} ins Backup-Verzeichnis"
    fi
    execute_command "git clone --bare \"${DOTFILES_REPO}\" \"${DOTDIR}\"" "Klone bare Repository"
    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${WORKSPACE_DIR}\" config --local status.showUntrackedFiles no" "Konfiguriere Dotfiles"

    log_message "i" "Entferne alte Dotfiles im Home-Verzeichnis..." "$YELLOW"
    find "${WORKSPACE_DIR}" -maxdepth 1 -type f -exec rm -rf {} \; || safe_exit "Entfernen alter Dotfiles fehlgeschlagen"

    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${WORKSPACE_DIR}\" checkout" "Checke Dotfiles aus"
}

# Funktion zum Parsen von Argumenten
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --local)
                WORKSPACE_DIR="$2"
                shift
                ;;
            --docker)
                log_message "i" "Docker-Umgebung erkannt. Fortfahren ohne Benutzeraufforderung." "$YELLOW"
                ;;
            *)
                safe_exit "Unbekannte Option: $1"
                ;;
        esac
        shift
    done
}

# Funktion zum Umgang mit wiederholter Skriptausführung
handle_repeated_execution() {
    if [ -d "${BACKUP_DIR}" ]; then
        log_message "!" "Backup-Verzeichnis existiert bereits. Vorheriges Backup wird überschrieben." "$YELLOW"
    fi
    if [ -d "${DOTDIR}" ]; then
        log_message "!" "Dotfiles-Verzeichnis existiert bereits. Es wird ins Backup-Verzeichnis verschoben." "$YELLOW"
    fi
}

# Hauptskriptausführung beginnt hier
main() {
    parse_args "$@"
    install_dependencies
    handle_repeated_execution
    backup_files
    initialize_and_checkout_dotfiles
    log_message "✔" "Deployment erfolgreich abgeschlossen." "$GREEN"
}

main "$@"
