# Add standard system paths
#export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

add_bin_to_path() {
  local bin_dir="$HOME/bin"
  if [[ -d "$bin_dir" ]]; then
    # Finde alle Unterverzeichnisse von ~/bin und füge sie zum PATH hinzu
    PATH=$(find "$bin_dir" -type d | tr '\n' ':' | sed 's/:$//'):$PATH
  fi
}

[[ -d "$HOME/.pyenv/bin" ]] && export PATH="$HOME/.pyenv/bin:$PATH"

# Docker CLI plugins
if [[ -d "$HOME/.docker/cli-plugins" ]]; then
  export PATH="$PATH:$HOME/.docker/cli-plugins"
fi

# Node.js development environment
# Check if the .nvm directory exists before attempting to use `nvm`
if [[ -d "$HOME/.nvm" ]]; then
  # Ensure this script is executed directly, not sourced, to correctly initialize nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  # Now safely add Node.js binaries to PATH
  if type nvm > /dev/null 2>&1; then
    export PATH="$PATH:$HOME/.nvm/versions/node/$(nvm current)/bin"
  fi
fi

# Go development environment
if [[ -d "/usr/lib/go" ]] && [[ -d "$HOME/go/bin" ]]; then
  export GOROOT="/usr/lib/go"co
  export PATH="$PATH:$HOME/go/bin"
fi

# Rust development environment
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$PATH:$HOME/.cargo/bin"
fi
