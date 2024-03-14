# Verwenden des neuesten Arch Linux-Images als Basis
FROM archlinux:latest

# Update System und installiere benötigte Pakete
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python-pip go openssh fontconfig && \
    # Reinige den Pacman-Cache, um die Größe des Images zu reduzieren
    pacman -Scc --noconfirm

# Erstelle einen neuen Benutzer 'developer' mit Zsh als Standard-Shell
RUN useradd -m -s /bin/zsh developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    # Setze ein Standardpasswort für den Benutzer 'developer'
    echo "developer:developer" | chpasswd

# Setze den Benutzer 'developer' als aktuellen Benutzer
USER developer
# Setze das Arbeitsverzeichnis auf das Home-Verzeichnis des Benutzers
WORKDIR /home/developer

# Erstelle eine neue .zshrc für den Benutzer 'developer'
#RUN echo "export PATH=\$PATH:/usr/local/bin" > /home/developer/.zshrc && \
#    chown developer:developer /home/developer/.zshrc

# Herunterladen des Skripts in das Home-Verzeichnis des Benutzers und Ausführungsberechtigungen setzen
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh -o /home/developer/deploy.sh && \
    chmod +x /home/developer/deploy.sh

# Setze den Standardbefehl oder das Standardprogramm, das ausgeführt werden soll, wenn der Container gestartet wird
CMD ["/bin/zsh", "-c", "/home/developer/deploy.sh --local"]
