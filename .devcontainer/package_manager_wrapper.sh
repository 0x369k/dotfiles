#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_file="/tmp/package_manager_wrapper.log"

log() {
    local message="$1"
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$log_file"
}

verbose() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}"
}

common_packages=(
    file
    iproute2
    procps
    sudo
    lsb-release
    zlib1g
    tree
    vim
    nano
    ncurses-dev
    man
    telnet
    unzip
    zsh
    apt-transport-https
    jq
    gnupg2
    git
    subversion
    curl
    make
    sudo
    locales
    autoconf
    automake
)

distro_specific_packages=()

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    source /etc/os-release
    case "${ID,,}" in
        ubuntu|debian)
            distro_specific_packages+=(
                python3-minimal
                python3-pip
                libffi-dev
                python3-venv
                golang-go
                rsync
                socat
                build-essential
            )
            ;;
        alpine)
            distro_specific_packages+=(
                python3
                py3-pip
                libffi-dev
                go
                rsync
                socat
                build-base
            )
            ;;
        arch|archlinux)
            distro_specific_packages+=(
                python
                python-pip
                libffi
                go
                rsync
                socat
                base-devel
            )
            ;;
        *)
            verbose "[${RED}✘${NC}] Unsupported Linux distribution: ${ID}" "$RED"
            exit 1
            ;;
    esac
else
    verbose "[${RED}✘${NC}] Unable to detect Linux distribution" "$RED"
    exit 1
fi

all_packages=("${common_packages[@]}" "${distro_specific_packages[@]}")

install_packages() {
    local packages=("$@")
    local failed_packages=()

    for package in "${packages[@]}"; do
        verbose "[${BLUE}i${NC}] Installing package: $package" "$BLUE"
        if ! package_manager_install "$package"; then
            failed_packages+=("$package")
            verbose "[${RED}✘${NC}] Failed to install package: $package" "$RED"
            log "[${RED}✘${NC}] Failed to install package: $package"
        else
            verbose "[${GREEN}✔${NC}] Package $package installed successfully" "$GREEN"
            log "[${GREEN}✔${NC}] Package $package installed successfully"
        fi
    done

    if [ "${#failed_packages[@]}" -gt 0 ]; then
        verbose "[${YELLOW}!${NC}] Some packages failed to install: ${failed_packages[*]}" "$YELLOW"
        log "[${YELLOW}!${NC}] Some packages failed to install: ${failed_packages[*]}"
    fi
}

package_manager_install() {
    local package="$1"

    case "${ID,,}" in
        ubuntu|debian)
            if ! apt-get install -y "$package" >> "$log_file" 2>&1; then
                return 1
            fi
            ;;
        alpine)
            if ! apk add --no-cache "$package" >> "$log_file" 2>&1; then
                return 1
            fi
            ;;
        arch|archlinux)
            if ! pacman -S --noconfirm "$package" >> "$log_file" 2>&1; then
                return 1
            fi
            ;;
        *)
            verbose "[${RED}✘${NC}] Unsupported Linux distribution: ${ID}" "$RED"
            return 1
            ;;
    esac

    return 0
}

install_packages "${all_packages[@]}"