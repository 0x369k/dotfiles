ARG BASE_IMAGE=archlinux:latest
FROM $BASE_IMAGE

# Copy the package_manager_wrapper.sh script into the container
COPY package_manager_wrapper.sh /usr/local/bin/package_manager_wrapper.sh
RUN chmod +x /usr/local/bin/package_manager_wrapper.sh

# Install required packages using the wrapper script
RUN /usr/local/bin/package_manager_wrapper.sh base-devel git vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python-pip go sudo lsb-release autoconf automake zsh

# Create a new user with bash as the default shell
ARG USERNAME=developer
RUN useradd -m -s /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    echo "$USERNAME:$USERNAME" | chpasswd

USER $USERNAME
WORKDIR /home/$USERNAME

# Download and prepare the deploy script
RUN curl -Lks https://raw.githubusercontent.com/0x369k/dotfiles/main/.zsh/deploy.sh -o /home/$USERNAME/deploy.sh && \
    chmod +x /home/$USERNAME/deploy.sh

CMD ["/bin/bash", "-c", "cd /home/$USERNAME/workspace && /home/$USERNAME/deploy.sh --local"]