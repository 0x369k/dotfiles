# Add standard system paths
#export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
(( $+commands[vivid] )) && { typeset -gx LS_COLORS="$(vivid generate snazzy)" 2> /dev/null; }

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


# Zsh Autosuggestions Configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#073642,bg=#839496,bold,underline"
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100

# Initialize color support and additional utilities
autoload -Uz colors && colors
autoload -Uz add-zsh-hook
autoload -Uz select-word-style && select-word-style default
autoload -Uz vcs_info
autoload -Uz terminfo
autoload -Uz bashcompinit

# Initialize command line editing with external editor
autoload -z edit-command-line
zle -N edit-command-line


# Conditional Setup for Specific TTY
if [[ "$TTY" == "/dev/tty4" ]]; then
  export XDG_SESSION_TYPE="tty"
fi

# FZF Default Options
export FZF_DEFAULT_OPTS='
 --color=fg:#cbccc6,bg:#1f2430,hl:229,fg+:#ebdbb2,bg+:#191e2a,hl+:230
 --color info:#AC82D6,prompt:#bdae93,spinner:#fabd2f,pointer:#AC82D6,marker:#fe8019,header:#665c54'
