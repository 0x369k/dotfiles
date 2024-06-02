# showkey -a 
# bindkey -l                           will give you a list of existing keymap names.
# zle -al                              lists all registered zle commands
#
#        ^ = Ctrl
#       ^[ = Alt
# \e or \E = Escape
# bindkey "^Q^L" $WIDGET
#

# fzf widget for file/command selection
fzf-widget() {
    local selection
    selection=$(fzf <"$TTY") || return
    LBUFFER+="$selection"
}
zle -N fzf-widget
bindkey '^f' fzf-widget

# Keybindings for navigation and editing
bindkey "^[[3~" delete-char     # DELETE
bindkey "^[[2~" overwrite-mode  # Insert
bindkey '^[h' backward-word     # Alt + h
bindkey '^[l' forward-word      # Alt + l
bindkey '^[j' backward-char     # Alt + j
bindkey '^[k' forward-char      # Alt + k
bindkey '^[o' delete-word       # Alt + o
bindkey '^[i' delete-char       # Alt + i
bindkey '^[^H' backward-word    # Ctrl + h

# Home key - move to the beginning of the line
bindkey "^[[H" beginning-of-line
bindkey "^[[1~" beginning-of-line  # Alternative depending on the terminal

# End key - move to the end of the line
bindkey "^[[F" end-of-line
bindkey "^[[4~" end-of-line  # Alternative depending on the terminal

# Ctrl+Right arrow - move to the next word
bindkey "^[Oc" forward-word
bindkey "^[[1;5C" forward-word  # Alternative depending on the terminal

# Ctrl+Left arrow - move to the beginning of the word
bindkey "^[Od" backward-word
bindkey "^[[1;5D" backward-word  # Alternative depending on the terminal

# Page Up - move up through the history
bindkey "^[[5~" history-beginning-search-backward

# Page Down - move down through the history
bindkey "^[[6~" history-beginning-search-forward

# Alt+Backspace - delete the word before the cursor
bindkey "^[^?" backward-kill-word
bindkey "^[^H" backward-kill-word  # Alternative depending on the terminal

# Ctrl+u - delete from the cursor to the beginning of the line
bindkey "^u" backward-kill-line

# Ctrl+k - delete from the cursor to the end of the line
bindkey "^k" kill-line

# Ctrl+a - move to the beginning of the line (alternative to Home)
bindkey "^a" beginning-of-line

# Ctrl+e - move to the end of the line (alternative to End)
bindkey "^e" end-of-line


# Alias expansion widget
zle -C alias-expansion complete-word _generic
bindkey '^a' alias-expansion

# navi widget for interactive cheatsheet tool
navi-widget() {
    eval "$(navi widget zsh)"
}
zle -N navi-widget
bindkey '^g' navi-widget

# Insert output of the last command into the current command line
zmodload -i zsh/parameter
insert-last-command-output() {
    LBUFFER+="$(eval $history[$((HISTCMD-1))])"
}
zle -N insert-last-command-output
bindkey "^L" insert-last-command-output

# Tetris game keybinding
autoload -Uz tetris
zle -N tetris
bindkey '^t^e' tetris

