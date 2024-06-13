# Use the latest Arch Linux image as the base
FROM archlinux:latest

# Define the default username as an argument
ARG USER_NAME=developer

# Update system and install necessary packages
RUN pacman -Syu --noconfirm --needed && \
    pacman -S --noconfirm --needed sudo docker fontconfig base-devel git zsh vim nano tree curl wget man-db man-pages texinfo iproute2 htop python python-pip go openssh && \
    # Clean the pacman cache to reduce the image size
    pacman -Scc --noconfirm

# Create a new user '$USER_NAME' with Zsh as the default shell
RUN useradd -m -s /usr/bin/zsh $USER_NAME && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER_NAME && \
    chmod 0440 /etc/sudoers.d/$USER_NAME && \
    echo "$USER_NAME:$USER_NAME" | chpasswd

# Set the working directory to the user's home directory
WORKDIR /home/$USER_NAME

# Run the deploy script on container startup
CMD ["/bin/bash", "-c", "curl -fsSL https://github.com/0x369k/dotfiles/raw/main/.zsh/deploy.sh -o /home/developer/deploy.sh && /bin/bash /home/developer/deploy.sh && /usr/bin/zsh"]

# Set the default command or program to run when the container starts
USER $USER_NAME

