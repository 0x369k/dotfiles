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
    local installed_packages=()

    for package in "${packages[@]}"; do
        if ! is_package_installed "$package"; then
            verbose "[${BLUE}i${NC}] Installing package: $package" "$BLUE"
            local install_command=$(get_package_manager_command install "$package")
            local install_output=$(eval "$install_command" 2>&1)
            local install_exit_code=$?

            if [ $install_exit_code -ne 0 ]; then
                failed_packages+=("$package")
                verbose "[${RED}✘${NC}] Failed to install package: $package" "$RED"
                log "[${RED}✘${NC}] Failed to install package: $package"
                log "Error output: $install_output"
            else
                installed_packages+=("$package")
                verbose "[${GREEN}✔${NC}] Package $package installed successfully" "$GREEN"
                log "[${GREEN}✔${NC}] Package $package installed successfully"
            fi
        else
            verbose "[${YELLOW}!${NC}] Package $package is already installed" "$YELLOW"
            log "[${YELLOW}!${NC}] Package $package is already installed"
        fi
    done

package_manager_install() {
    local action="$1"
    local package="$2"

    case "${ID,,}" in
        ubuntu|debian)
            echo "apt-get $action -y $package"
            ;;
        alpine)
            echo "apk $action --no-cache $package"
            ;;
        arch|archlinux)
            echo "pacman -S --noconfirm $package"
            ;;
        *)
            verbose "[${RED}✘${NC}] Unsupported Linux distribution: ${ID}" "$RED"
            return 1
            ;;
    esac
}

install_packages "${all_packages[@]}"