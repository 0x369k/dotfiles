FROM $BASE_IMAGE
# Copy the package_manager_wrapper.sh script into the container
COPY package_manager_wrapper.sh /usr/local/bin/package_manager_wrapper.sh
RUN chmod +x /usr/local/bin/package_manager_wrapper.sh
# Install required packages using the wrapper script
RUN /usr/local/bin/package_manager_wrapper.sh base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python3-pip go sudo lsb-release locales autoconf automake
RUN apt-get update && apt-get install --no-install-recommends -yq file dirmngr iproute2 procps sudo lsb-release \
zlib1g tree vim nano ncurses-dev man telnet unzip zsh apt-transport-https jq gnupg2 git subversion curl make sudo \
locales autoconf automake python3-minimal python3-pip libffi-dev python3-venv golang-go rsync socat build-essential \
less vim htop && apt-get clean -y && rm -rf /var/lib/apt/lists/*
# Create a new user with Zsh as the default shell
ARG USERNAME=developer
RUN useradd -m -s /usr/bin/zsh $USERNAME && \
 echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USERNAME && \
 chmod 0440 /etc/sudoers.d/$USERNAME && \
 echo "$USERNAME:$USERNAME" | chpasswd
USER $USERNAME
WORKDIR /home/$USERNAME
# Download and prepare the deploy script
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh -o /home/$USERNAME/deploy.sh && \
 chmod +x /home/$USERNAME/deploy.sh
CMD ["/bin/zsh"]