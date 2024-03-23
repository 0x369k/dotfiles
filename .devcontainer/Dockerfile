FROM ubuntu:rolling

ARG USERNAME=defaultuser
ARG IMAGE_NAME=default-image-name
ARG CONTAINER_NAME=default-container-name

RUN apt-get update && apt-get install --no-install-recommends -yq \
    file dirmngr iproute2 procps sudo lsb-release zlib1g tree vim nano \
    ncurses-dev man telnet unzip zsh apt-transport-https jq gnupg2 git \
    subversion curl make sudo locales autoconf automake python3-minimal \
    python3-pip libffi-dev python3-venv golang-go rsync socat build-essential \
    less vim htop && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE:en
ENV LC_ALL de_DE.UTF-8
ENV TERM xterm-256color
ENV SHELL=/bin/zsh

RUN useradd -m $USERNAME && \
    adduser $USERNAME sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod --shell /bin/zsh $USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

# Download and prepare the deploy script
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh -o /home/$USERNAME/deploy.sh && \
    chmod +x /home/$USERNAME/deploy.sh

CMD ["/bin/bash", "-c", "cd /home/$USERNAME/workspace && /home/$USERNAME/deploy.sh --local"]

ENTRYPOINT ["zsh", "-i", "-l"]