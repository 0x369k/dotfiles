FROM ubuntu:latest
# Standardwerte für build-time Variablen definieren
ARG USERNAME=developer

# Paketliste aktualisieren und benötigte Pakete installieren
RUN apt-get update && apt-get install --no-install-recommends -yq \
    curl wget file dirmngr iproute2 procps sudo lsb-release zlib1g tree vim nano \
    ncurses-dev man telnet unzip zsh apt-transport-https jq gnupg2 git \
    subversion curl make sudo locales autoconf automake python3-minimal \
    python3-pip libffi-dev python3-venv golang-go rsync socat build-essential \
    less vim htop && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Locale einstellen
RUN sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# Umgebungsvariablen setzen
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE:en
ENV LC_ALL de_DE.UTF-8
ENV TERM xterm-256color<
ENV SHELL=/bin/bash

# Benutzer hinzufügen und zum sudoers ohne Passwortabfrage hinzufügen
RUN useradd -m $USERNAME && \
    adduser $USERNAME sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod --shell /bin/zsh $USERNAME

# Als der erstellte Benutzer arbeiten und ins Home-Verzeichnis wechseln
USER $USERNAME
WORKDIR /home/$USERNAME

RUN wget https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/entrypoint.sh -O /home/$USERNAME/entrypoint.sh && \
    chmod +x /home/$USERNAME/entrypoint.sh

ENTRYPOINT ["/home/$USERNAME/entrypoint.sh"]