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

# Log- und Fehlerfunktionen
log_error() {
    echo -e "${ERROR} $1" >&2
    logger -p user.err "$1"
    exit 1
}

info() {
    echo -e "${INFO} $1"
    logger -p user.info "$1"
}

warn() {
    echo -e "${WARN} $1"
    logger -p user.warn "$1"
}

success() {
    echo -e "${CHECK} $1"
    logger -p user.info "$1"
}

# Abhängigkeiten überprüfen
check_dependencies() {
    command -v git >/dev/null 2>&1 || log_error "Git ist nicht installiert. Bitte installieren Sie Git und versuchen Sie es erneut."
#    command -v docker >/dev/null 2>&1 || log_error "Docker ist nicht installiert. Bitte installieren Sie Docker und versuchen Sie es erneut."
#    command -v docker-compose >/dev/null 2>&1 || log_error "Docker Compose ist nicht installiert. Bitte installieren Sie Docker Compose und versuchen Sie es erneut."
}

# Backup bestehender Dotfiles
backup_dotfiles() {
    dotfiles=$(git --git-dir="$GIT_DIR" --work-tree="$HOME" ls-tree -r HEAD --name-only)
    backup_needed=false

    for file in $dotfiles; do
        if [ -f "$HOME/$file" ] || [ -d "$HOME/$file" ]; then
            warn "$file wird ersetzt und nach $BACKUP_DIR/$file gesichert"
            backup_needed=true
        fi
    done

    if [ "$backup_needed" = true ]; then
        read -p "Möchten Sie fortfahren und diese Dateien sichern und ersetzen? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Operation abgebrochen"
        fi

        info "Sichern bestehender Dotfiles nach $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR" || log_error "Konnte Backup-Verzeichnis nicht erstellen"

        for file in $dotfiles; do
            if [ -f "$HOME/$file" ] || [ -d "$HOME/$file" ]; then
                mkdir -p "$BACKUP_DIR/$(dirname "$file")"
                mv "$HOME/$file" "$BACKUP_DIR/$file" || log_error "Konnte $file nicht sichern"
                success "$file gesichert nach $BACKUP_DIR/$file"
            fi
        done
    else
        info "Keine Dateien zum Sichern gefunden."
    fi
}

# Repository initialisieren
initialize_repo() {
    if [ ! -d "$GIT_DIR/HEAD" ]; then
        info "Initialisiere Git-Repository"
        git --git-dir="$GIT_DIR" init --bare || log_error "Konnte Git-Repository nicht initialisieren"
    else
        info "Git-Repository existiert bereits"
        warn "Git-Repository existiert bereits. Möchten Sie fortfahren und bestehende Konfiguration überschreiben?"
        read -p "Bestätigen Sie mit [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Operation abgebrochen"
        fi
    fi
}

# Docker-Container einrichten
setup_docker_container() {
    shared_folder=$1
    info "Shared Folder wird auf $shared_folder gesetzt"
    SHARED_FOLDER="$shared_folder" docker-compose -f .devcontainer/docker-compose.yml up -d --build
    docker exec -it zsh_dev_container /bin/zsh
}

# Hauptmenü
show_main_menu() {
    PS3="Bitte wählen Sie eine Option: "
    options=("Dotfiles lokal installieren" "Dotfiles in Docker-Container installieren" "Beenden")
    select opt in "${options[@]}"
    do
        case $opt in
            "Dotfiles lokal installieren")
                install_dotfiles_local
                ;;
            "Dotfiles in Docker-Container installieren")
                show_docker_menu
                ;;
            "Beenden")
                break
                ;;
            *) echo "Ungültige Option $REPLY";;
        esac
    done
}

# Docker-Menü
show_docker_menu() {
    PS3="Bitte wählen Sie einen shared Ordner: "
    default_location="$HOME/docker_shared"
    current_location=$(pwd)
    options=("Default Location ($default_location)" "Aktueller Pfad ($current_location)" "Eigenen Ordner wählen" "Zurück")
    select opt in "${options[@]}"
    do
        case $opt in
            "Default Location ($default_location)")
                shared_folder="$default_location"
                ;;
            "Aktueller Pfad ($current_location)")
                shared_folder="$current_location"
                ;;
            "Eigenen Ordner wählen")
                read -p "Bitte geben Sie den Pfad zum eigenen Ordner ein: " custom_folder
                shared_folder="$custom_folder"
                ;;
            "Zurück")
                show_main_menu
                ;;
            *) echo "Ungültige Option $REPLY";;
        esac
        [ -n "$shared_folder" ] && setup_docker_container "$shared_folder" && break
    done
}

# Dotfiles lokal installieren
install_dotfiles_local() {
    # Prüfen, ob das Repository-Verzeichnis existiert
    if [ -d "$DOTFILES_DIR" ]; then
        info "Dotfiles-Verzeichnis existiert bereits"
    else
        info "Erstelle Dotfiles-Verzeichnis"
        mkdir -p "$DOTFILES_DIR" || log_error "Konnte Dotfiles-Verzeichnis nicht erstellen"
    fi

    # Repository initialisieren
    initialize_repo

    # Klonen des Remote-Repositorys, falls eine URL angegeben ist
    if [ "$1" ]; then
        REPO_URL="$1"
        info "Klonen des Remote-Repositorys von $REPO_URL"
        if git --git-dir="$GIT_DIR" remote get-url origin &>/dev/null; then
            warn "Remote-Repository 'origin' existiert bereits. Aktualisiere Remote-URL."
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
    info "Füge .dotfiles zu .gitignore hinzu"
    echo ".dotfiles" >> "$HOME/.gitignore"

    info "Dotfiles-Installation abgeschlossen"
}

# Exit trap einrichten, um das Skript zu löschen
cleanup() {
    info "Entferne das Skript"
    if [[ -f "$0" ]]; then
        rm -- "$0"
    fi
}
trap cleanup EXIT

# Hauptlogik
check_dependencies
show_main_menu
