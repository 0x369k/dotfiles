ARG BASE_IMAGE=ubuntu:latest
FROM $BASE_IMAGE

# Kopiere das package_manager_wrapper.sh-Skript in den Container
COPY package_manager_wrapper.sh /usr/local/bin/package_manager_wrapper.sh
RUN chmod +x /usr/local/bin/package_manager_wrapper.sh

# Installiere die benötigten Pakete mit dem Wrapper-Skript
RUN /usr/local/bin/package_manager_wrapper.sh base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python3-pip go sudo lsb-release locales autoconf automake 

RUN apt-get update && apt-get install --no-install-recommends -yq file dirmngr iproute2 procps sudo lsb-release \
zlib1g tree vim nano ncurses-dev man telnet unzip zsh apt-transport-https jq gnupg2 git subversion curl make sudo \
locales autoconf automake python3-minimal python3-pip libffi-dev python3-venv golang-go rsync socat build-essential \
less vim htop && apt-get clean -y && rm -rf /var/lib/apt/lists/*


# Erstelle einen neuen Benutzer 'developer' mit Zsh als Standard-Shell
RUN useradd -m -s /usr/bin/zsh developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    echo "developer:developer" | chpasswd

USER developer
WORKDIR /home/developer

# Herunterladen und Vorbereiten des Deploy-Skripts
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh -o /home/developer/deploy.sh && \
    chmod +x /home/developer/deploy.sh

CMD ["/bin/zsh"]