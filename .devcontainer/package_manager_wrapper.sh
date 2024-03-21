#!/bin/bash

# Funktion zum Erkennen des Paketmanagers basierend auf der Betriebssystem-ID
detect_package_manager() {
    if [ -f /etc/os-release ]; then
        # Verwenden von /etc/os-release, um die Betriebssystem-ID zu ermitteln
        . /etc/os-release
        case $ID in
            alpine)
                echo "apk"
                ;;
            arch)
                echo "pacman"
                ;;
            debian|ubuntu)
                echo "apt-get"
                ;;
            fedora|centos|rhel)
                echo "yum"
                ;;
            gentoo)
                echo "emerge"
                ;;
            opensuse|sles)
                echo "zypper"
                ;;
            *)
                echo "Unbekannter Paketmanager für $ID. Bitte manuell installieren." >&2
                exit 1
                ;;
        esac
    else
        echo "Die Datei /etc/os-release wurde nicht gefunden. Bitte manuell installieren." >&2
        exit 1
    fi
}

# Funktion zum Installieren von Paketen
install_packages() {
    package_manager=$(detect_package_manager)
    case $package_manager in
        apk)
            apk add --no-cache "$@"
            ;;
        pacman)
            pacman -Syu --noconfirm "$@"
            ;;
        apt-get)
            apt-get update && apt-get install -y "$@"
            ;;
        yum)
            yum install -y "$@"
            ;;
        emerge)
            emerge "$@"
            ;;
        zypper)
            zypper install -y "$@"
            ;;
    esac
}

# Aufruf der Funktion zum Installieren von Paketen mit den angegebenen Argumenten
install_packages "$@"