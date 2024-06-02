# Dotfiles

Optimized Zsh configurations for enhanced productivity on Arch Linux & KDE, featuring the powerful Zi plugin manager for a seamless, modular command line experience. Includes Docker & VS Code DevContainer setups for consistent development environments. Perfect for those seeking efficiency and customization in their daily computing tasks.

## Features

- **Zsh Configurations**: Enhanced Zsh setup with Zi plugin manager for optimal performance and modularity.
- **Docker Setup**: Includes Docker configurations for consistent development environments.
- **VS Code DevContainer**: Pre-configured DevContainer setups for streamlined development.
- **Arch Linux & KDE**: Tailored for Arch Linux and KDE environments.

## Installation

### Prerequisites

- Git
- Docker
- Docker Compose
- Zsh

### Steps

1. **Clone the repository**:
    ```sh
    git clone https://github.com/0x369k/dotfiles.git ~/.dotfiles
    ```

2. **Run the installation script**:
    ```sh
    cd ~/.dotfiles
    ./zsh/deploy.sh
    ```

### Alternative Installation via Curl

You can also run the installation script directly using `curl`:
```sh
curl -fsSL https://github.com/0x369k/dotfiles/raw/main/.zsh/deploy.sh | bash
