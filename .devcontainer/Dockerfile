ARG BASE_IMAGE=archlinux:latest
FROM $BASE_IMAGE

# Herunterladen und Ausführen des Wrapper-Skripts
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.devcontainer/package_manager_wrapper.sh -o /usr/local/bin/package_manager_wrapper.sh && \
    chmod +x /usr/local/bin/package_manager_wrapper.sh && \
    /usr/local/bin/package_manager_wrapper.sh base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python-pip go openssh

# Erstelle einen neuen Benutzer 'developer' mit Zsh als Standard-Shell
RUN useradd -m -s /usr/bin/zsh developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    echo "developer:developer" | chpasswd

USER developer
WORKDIR /home/developer

# Herunterladen, Ausführbar machen und Ausführen des Deploy-Skripts
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh -o /home/developer/deploy.sh && \
    chmod +x /home/developer/deploy.sh && \
    /home/developer/deploy.sh

CMD ["/bin/zsh"]