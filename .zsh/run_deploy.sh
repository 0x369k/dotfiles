#!/usr/bin/env bash

# Skript-URL und temporäres Skript
SCRIPT_URL="https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh"
TEMP_SCRIPT="/tmp/deploy_temp.sh"

# Exit-Trap-Funktion zum Aufräumen
cleanup() {
    echo "Bereinige temporäre Dateien..."
    [ -f "${TEMP_SCRIPT}" ] && rm -f "${TEMP_SCRIPT}"
}
trap cleanup EXIT

# Skript herunterladen und ausführen
curl -Lks "$SCRIPT_URL" -o "$TEMP_SCRIPT" || { echo "Fehler beim Herunterladen des Skripts"; exit 1; }
chmod +x "$TEMP_SCRIPT" || { echo "Fehler beim Setzen der Ausführungsberechtigung für das Skript"; exit 1; }
bash "$TEMP_SCRIPT"