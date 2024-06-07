#!/usr/bin/env bash

# Farbcodes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Keine Farbe
BOLD='\033[1m'
NORMAL='\033[0m'

# Standardwerte für Konfigurationen
DOTFILES_REPO="https://github.com/0x369k/dotfiles.git"
DOTDIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y-%m-%d_%H-%M-%S)"
TEMP_DIR="/tmp/dotfiles_temp"
LOG_FILE="/tmp/deploy.log"
SCRIPT_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh"
TEMP_SCRIPT="/tmp/deploy_temp.sh"

# Konfiguration laden, falls vorhanden
CONFIG_FILE="${HOME}/.deploy_config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Protokollierungsfunktion für allgemeine Nachrichten
log_message() {
    local status="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}${status}${NC} ${message}" | tee -a "$LOG_FILE"
}

# Verbesserte safe_exit Funktion mit Fehlerprotokollierung
safe_exit() {
    local message="$1"
    local code="${2:-1}" # Standard Exit-Status 1
    log_message "✘" "$message" "$RED"
    [ -d "${TEMP_DIR}" ] && rm -rf "${TEMP_DIR}"
    [ -f "${TEMP_SCRIPT}" ] && rm -f "${TEMP_SCRIPT}"
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
        if [ -e "${HOME}/${relative_path}" ]; then
            if mv "${HOME}/${relative_path}" "${target_dir}/"; then
                log_message "✔" "Sichere: ${BOLD}${HOME}/${relative_path}${NORMAL} nach ${BOLD}${target_dir}/${relative_path}${NORMAL}" "$GREEN"
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
    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" config --local status.showUntrackedFiles no" "Konfiguriere Dotfiles"

    log_message "i" "Entferne alte Dotfiles im Home-Verzeichnis..." "$YELLOW"
    find "${HOME}" -maxdepth 1 -type f -exec rm -rf {} \; || safe_exit "Entfernen alter Dotfiles fehlgeschlagen"

    execute_command "git --git-dir=\"${DOTDIR}\" --work-tree=\"${HOME}\" checkout" "Checke Dotfiles aus"
}

# Benutzer zur Bestätigung auffordern, nicht-interaktiven Shell berücksichtigen
prompt_user() {
    if [ -t 1 ]; then
        echo -e "${YELLOW}Folgende Aktionen werden durchgeführt:${NC}"
        echo -e "${YELLOW}1. Sichern bestehender Dateien in ${BACKUP_DIR}.${NC}"
        echo -e "${YELLOW}2. Klonen des Dotfiles-Repositories in ein temporäres Verzeichnis.${NC}"
        echo -e "${YELLOW}3. Verschieben bestehender Dotfiles nach ${BACKUP_DIR}.${NC}"
        echo -e "${YELLOW}4. Klonen des bare Repositories in ${DOTDIR}.${NC}"
        echo -e "${YELLOW}5. Konfigurieren und Auschecken der Dotfiles in das Home-Verzeichnis.${NC}"
        echo -e "${YELLOW}6. Überprüfen und ggf. Installieren von Abhängigkeiten (git, curl).${NC}"
        
        read -p "$(echo -e ${YELLOW}? Möchten Sie mit dem Deployment fortfahren? [y/N]: ${NC})" choice
        case "$choice" in
            y|Y ) 
                log_message "i" "Benutzer hat zugestimmt." "$YELLOW"
                log_message "i" "Die folgenden Dateien werden gesichert:" "$YELLOW"
                for file in $(find "${TEMP_DIR}" -type f -print); do
                    relative_path="${file#"${TEMP_DIR}/"}"
                    if [ -e "${HOME}/${relative_path}" ]; then
                        echo -e "${YELLOW}  ${HOME}/${relative_path} -> ${BACKUP_DIR}/${relative_path}${NC}"
                    fi
                done
                ;;
            * ) safe_exit "Deployment vom Benutzer abgebrochen.";;
        esac
    else
        log_message "i" "Nicht-interaktive Shell erkannt. Fortfahren ohne Benutzeraufforderung." "$YELLOW"
        return 0
    fi
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

# Funktionen zum Parsen von Argumenten
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --repo)
                DOTFILES_REPO="$2"
                shift
                ;;
            --dotdir)
                DOTDIR="$2"
                shift
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift
                ;;
            --help)
                echo "Usage: $0 [--repo REPO_URL] [--dotdir DOTDIR] [--backup-dir BACKUP_DIR] [--log-file LOG_FILE]"
                exit 0
                ;;
            *)
                echo "Unknown parameter: $1"
                exit 1
                ;;
        esac
        shift
    done
}

# Funktion zum Herunterladen und Ausführen des Skripts
download_and_execute_script() {
    log_message "i" "Lade das Skript herunter..." "$YELLOW"
    curl -Lks "$SCRIPT_URL" -o "$TEMP_SCRIPT" || safe_exit "Fehler beim Herunterladen des Skripts"
    log_message "i" "Führe das heruntergeladene Skript aus..." "$YELLOW"
    chmod +x "$TEMP_SCRIPT" || safe_exit "Fehler beim Setzen der Ausführungsberechtigung für das Skript"
    bash "$TEMP_SCRIPT"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        safe_exit "Fehler beim Ausführen des temporären Skripts"
    fi
    log_message "✔" "Ausführung des heruntergeladenen Skripts abgeschlossen." "$GREEN"
    rm -f "$TEMP_SCRIPT" || safe_exit "Fehler beim Löschen des temporären Skripts"
}

# Hauptskriptausführung beginnt hier
main() {
    parse_args "$@"
    if [ "$(basename "$0")" != "$(basename "$TEMP_SCRIPT")" ]; then
        download_and_execute_script
    else
        install_dependencies
        prompt_user
        handle_repeated_execution
        backup_files
        initialize_and_checkout_dotfiles
        log_message "✔" "Deployment erfolgreich abgeschlossen." "$GREEN"
    fi
}

main "$@"
