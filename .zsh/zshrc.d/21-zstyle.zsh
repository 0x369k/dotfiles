# Alias expansion in completion
zstyle ':completion:alias-expansion:*' completer _expand_alias

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Fuzzy and approximate matching
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# Beautification and grouping of completions
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' verbose yes

# Menu-driven completion
zstyle ':completion:*' menu select

# Improved SSH/Rsync/SCP autocomplete
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-ipaddr files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' 'localhost*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(127.0.0.1|::1)$'

# Persistent rehash
zstyle ':completion:*' rehash true

# Use fzf for filtering completion results
zstyle ':completion:*' completer _complete _fzf

# Use bat for previewing files when completing paths
zstyle ':completion:*:*:files' fzf-preview-command 'bat --color=always --line-range :500 {}'

zstyle ':completion:*' use-cache on

zstyle ':zi:plugins:ssh-agent' quiet yes
