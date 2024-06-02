#!/bin/bash

# Farben und Symbole definieren
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK="${GREEN}✔${NC}"
WARN="${YELLOW}⚠${NC}"
ERROR="${RED}✖${NC}"
INFO="${BLUE}ℹ${NC}"

# Verzeichnisse und Variablen definieren
DOTFILES_DIR="$HOME/.dotfiles"
GIT_DIR="$DOTFILES_DIR"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="$HOME/.dotfiles_backup_$TIMESTAMP"
LOG_FILE="$HOME/deploy_dotfiles.log"

# Sprachunterstützung
LANGUAGE="de"
set_language() {
    case $LANGUAGE in
        "de")
            INFO="ℹ"
            WARN="⚠"
            CHECK="✔"
            ERROR="✖"
            ;;
        "en")
            INFO="INFO:"
            WARN="WARNING:"
            CHECK="SUCCESS:"
            ERROR="ERROR:"
            ;;
        *)
            ;;
    esac
}
set_language

# Log- und Fehlerfunktionen
log_info() {
    echo -e "${INFO} $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${WARN} $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") WARN: $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${CHECK} $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") SUCCESS: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${ERROR} $1" >&2
    echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: $1" >> "$LOG_FILE"
    exit 1
}

# Abhängigkeiten überprüfen
check_dependencies() {
    command -v git >/dev/null 2>&1 || log_error "Git ist nicht installiert. Bitte installieren Sie Git und versuchen Sie es erneut."
}

# Backup bestehender Dotfiles
backup_dotfiles() {
    dotfiles=$(git --git-dir="$GIT_DIR" --work-tree="$HOME" ls-tree -r HEAD --name-only)
    backup_needed=false

    for file in $dotfiles; do
        if [ -f "$HOME/$file" ] || [ -d "$HOME/$file" ]; then
            log_warn "$file wird ersetzt und nach $BACKUP_DIR/$file gesichert"
            backup_needed=true
        fi
    done

    if [ "$backup_needed" = true ]; then
        read -p "Möchten Sie fortfahren und diese Dateien sichern und ersetzen? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Operation abgebrochen"
        fi

        log_info "Sichern bestehender Dotfiles nach $BACKUP_DIR"
        rsync -a "$HOME/" "$BACKUP_DIR/" --files-from=<(echo "$dotfiles") || log_error "Konnte Backup nicht erstellen"
    else
        log_info "Keine Dateien zum Sichern gefunden."
    fi
}

# Repository initialisieren
initialize_repo() {
    if [ ! -d "$GIT_DIR/HEAD" ]; then
        log_info "Initialisiere Git-Repository"
        git --git-dir="$GIT_DIR" init --bare || log_error "Konnte Git-Repository nicht initialisieren"
    else
        log_info "Git-Repository existiert bereits"

        # Sicherstellen, dass die bestehende Konfiguration nicht überschrieben wird
        log_warn "Git-Repository existiert bereits. Möchten Sie fortfahren und bestehende Konfiguration überschreiben?"
        read -p "Bestätigen Sie mit [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Operation abgebrochen"
        fi
    fi
}

# Exit trap einrichten, um das Skript zu löschen
cleanup() {
    log_info "Entferne das Skript"
    if [[ -f "$0" ]]; then
        rm -- "$0"
    fi
}
trap cleanup EXIT

# Hauptlogik
check_dependencies

# Prüfen, ob das Repository-Verzeichnis existiert
if [ -d "$DOTFILES_DIR" ]; then
    log_info "Dotfiles-Verzeichnis existiert bereits"
else
    log_info "Erstelle Dotfiles-Verzeichnis"
    mkdir -p "$DOTFILES_DIR" || log_error "Konnte Dotfiles-Verzeichnis nicht erstellen"
fi

# Repository initialisieren
initialize_repo

# Klonen des Remote-Repositorys, falls eine URL angegeben ist
if [ "$1" ]; then
    REPO_URL="$1"
    log_info "Klonen des Remote-Repositorys von $REPO_URL"
    if git --git-dir="$GIT_DIR" remote get-url origin &>/dev/null; then
        log_warn "Remote-Repository 'origin' existiert bereits. Aktualisiere Remote-URL."
        git --git-dir="$GIT_DIR" remote set-url origin "$REPO_URL" || log_error "Konnte Remote-Repository-URL nicht aktualisieren"
    else
        git --git-dir="$GIT_DIR" remote add origin "$REPO_URL" || log_error "Konnte Remote-Repository nicht hinzufügen"
    fi
    git --git-dir="$GIT_DIR" --work-tree="$HOME" fetch origin || log_error "Konnte Dotfiles nicht klonen"
fi

# Backup der bestehenden Dotfiles durchführen
backup_dotfiles

# Sicherstellen, dass alle Dotfiles korrekt aus dem Remote-Repository ausgecheckt werden
git --git-dir="$GIT_DIR" --work-tree="$HOME" reset --hard origin/main || log_error "Konnte Dotfiles nicht auschecken"
git --git-dir="$GIT_DIR" --work-tree="$HOME" checkout -f main || log_error "Konnte Dotfiles nicht auschecken"

# Ignorieren des .dotfiles-Verzeichnisses im Home-Verzeichnis
log_info "Füge .dotfiles zu .gitignore hinzu"
echo ".dotfiles" >> "$HOME/.gitignore"

log_info "Dotfiles-Installation abgeschlossen"