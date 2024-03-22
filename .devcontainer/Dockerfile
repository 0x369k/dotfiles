ARG BASE_IMAGE=ubuntu:latest
FROM $BASE_IMAGE
# Copy the package_manager_wrapper.sh script into the container
COPY package_manager_wrapper.sh /usr/local/bin/package_manager_wrapper.sh
RUN chmod +x /usr/local/bin/package_manager_wrapper.sh
# Install required packages using the wrapper script
RUN /usr/local/bin/package_manager_wrapper.sh base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python3-pip go sudo lsb-release locales autoconf automake
RUN /usr/local/bin/package_manager_wrapper.sh base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python-pip go sudo lsb-release autoconf automake
RUN pacman -Syu --noconfirm file iproute2 procps sudo zlib tree vim nano ncurses man unzip zsh jq git curl make sudo \
python python-pip libffi python-virtualenv go rsync socat base-devel \
less vim htop && pacman -Scc --noconfirm
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