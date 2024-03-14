alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ls='ls --color=auto'
alias rr='exec "$SHELL" -il'
alias cdp='_cdp'

# Clipboard Utility
alias copy_cmd='xsel -ib'

# Docker Compose alias
alias -g docker-compose='docker compose'

# Ausgabeumleitung und Filterung
alias -g 1DN='>/dev/null'
alias -g 2DN='2>/dev/null'
alias -g DN='1DN 2DN'
alias -g Z='| fzf'
alias -g CG='2>&1 |noglob grep --color=always'
alias -g G='2>&1 |noglob grep'
alias -g L='2>&1 |less'
alias -g B='2>&1 |bat'
alias -g C='| wc -l'

# Netzwerk-Utilities
alias get-ports="netstat -tulnp | grep LISTEN"
alias get-router="ip route | grep default"
alias get-ip="hostname -I"
alias get-ip-private="hostname -I | awk '{print $1}'"
alias get-ip-public="curl -4 ifconfig.co"

# Dotfiles Management
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias kdedot='git --git-dir=$HOME/.kdedotfiles --work-tree=$HOME'

# Erweiterte Dateilisten und Navigation
export lsd_params=('--icon' 'never' '--ignore-config')
alias lsb='lsd ${lsd_params:---icon never --ignore-config}'
export exa_params=('--git' '--no-icons' '--octal-permissions' '--header' '--group-directories-first' '--time-style=long-iso' '--group' '--color-scale')
alias exa="exa -g  --icons --long $exa_params --sort=changed --tree -L=1"
alias l='exa --git-ignore $exa_params'
alias ll='exa --all --long $exa_params'
alias llm='exa --all  --long --sort=modified $exa_params'
alias la='exa -lbhHigUmuSa'
alias lx='exa -lbhHigUmuSa@'
alias lt='exa --tree $exa_params'
alias tree='exa --tree $exa_params'

# Sichere Dateioperationen
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Start a new tmux session named 'work'
alias tmuxw="tmux new-session -s work"
# Attach to an existing tmux session named 'work'
alias tmuxa="tmux attach-session -t work"
# List all tmux sessions
alias tmuxl="tmux list-sessions"

# Paketmanager Wrapper
yay() {
    if command -v paru &> /dev/null; then
    echo "Verwende paru statt yay."
    paru "$@"
    fi
}