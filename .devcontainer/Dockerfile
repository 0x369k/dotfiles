ARG BASE_IMAGE=ubuntu:latest
FROM $BASE_IMAGE
# Copy the package_manager_wrapper.sh script into the container
COPY package_manager_wrapper.sh /usr/local/bin/package_manager_wrapper.sh
RUN chmod +x /usr/local/bin/package_manager_wrapper.sh
# Install required packages using the wrapper script
RUN /usr/local/bin/package_manager_wrapper.sh
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
CMD ["/bin/zsh", "-c", "cd /home/$USERNAME/workspace && /home/$USERNAME/deploy.sh --local"]