FROM ubuntu:20.04
# Standardwerte für build-time Variablen definieren
ARG USERNAME=developer
# Paketliste aktualisieren und benötigte Pakete installieren
RUN apt-get update && apt-get install --no-install-recommends -yq \
    file dirmngr iproute2 procps sudo lsb-release zlib1g tree vim nano \
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
ENV TERM xterm-256color
ENV SHELL=/bin/zsh
# Benutzer hinzufügen und zum sudoers ohne Passwortabfrage hinzufügen
RUN useradd -m $USERNAME && \
    adduser $USERNAME sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod --shell /bin/zsh $USERNAME
# Als der erstellte Benutzer arbeiten und ins Home-Verzeichnis wechseln
USER $USERNAME
WORKDIR /home/$USERNAME
# Hinzufügen des deploy.sh Skripts zum Image
COPY deploy.sh /deploy.sh
RUN chmod +x /deploy.sh

# Setzen der Z Shell-Konfiguration
RUN echo "autoload -Uz compinit && compinit" >> ~/.zshrc && \
    echo "setopt HIST_IGNORE_SPACE" >> ~/.zshrc && \
    echo "bindkey '^[[A' history-substring-search-up" >> ~/.zshrc && \
    echo "bindkey '^[[B' history-substring-search-down" >> ~/.zshrc

# Definieren des deploy.sh Skripts als Einstiegspunkt
ENTRYPOINT ["zsh", "-c", "/deploy.sh"]