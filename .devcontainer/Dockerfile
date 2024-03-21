ARG BASE_IMAGE=archlinux:latest
FROM $BASE_IMAGE

set -e

# Update System und installiere benötigte Pakete
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --no-install-recommends base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python-pip go openssh && \
    pacman -Scc --noconfirm && \
    rm -rf /var/lib/pacman/sync/* /var/cache/pacman/pkg/*

# Erstelle einen neuen Benutzer 'developer' mit Zsh als Standard-Shell
RUN useradd -m -s /usr/bin/zsh developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    echo "developer:developer" | chpasswd

USER developer
WORKDIR /home/developer

# Herunterladen und vorbereiten des Deploy-Skripts
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh -o /home/developer/deploy.sh && \
    chmod +x /home/developer/deploy.sh

CMD ["/bin/zsh"]