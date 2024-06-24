local DEBUG=false
if [[ $DEBUG == "true" ]]; then
    zmodload zsh/zprof
    NOW=$(date +"%Y-%m-%d_%H:%M:%S")
    PS4=$'%D{%M%S%.} %N:%i> '
    exec 3>&2 2>~/.cache/zi/log/startlog_$NOW.log
    setopt xtrace prompt_subst
fi

function check_ssh_x11 {
  if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    if [[ -z "$DISPLAY" && -n "$SSH_CONNECTION" ]]; then
      export DISPLAY=:0
      echo "SSH-Sitzung erkannt. DISPLAY gesetzt auf $DISPLAY."
    fi
  fi
}
check_ssh_x11

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Pfad zu deinen Zsh-Funktionen
function_dir="${HOME}/.zsh/functions"

# Funktion, um lokale Funktionen dynamisch zu laden
autoload_local_functions() {
  for func in $function_dir/*(.); do
    func_name="${func:t:r}"
    autoload -Uz $func_name
    # Erstellt einen Wrapper, um die Funktion beim ersten Aufruf zu laden
    eval "$func_name() { unfunction $func_name; . $func; $func_name \$@ }"
  done
}

# Rufe die Funktion beim Start auf
autoload_local_functions



ZSH_CONFIG_FILES=()
for init_path in ${ZDOTDIR:-$HOME/.zsh}/zshrc.d/*.zsh; do
    [[ "$(basename $init_path)" != "00-source.zsh" ]] && ZSH_CONFIG_FILES+=("$init_path")
done
[[ "$DEBUG" == "true" ]] && printf "%s\n" "${ZSH_CONFIG_FILES[@]}"
for file in "${ZSH_CONFIG_FILES[@]}"; do
  source "$file"
done

#autoload_lazyload() {
#  # Ensure the functions directory is added to the fpath
#if [[ -z ${fpath[(re)${ZDOTDIR:-$HOME/.zsh}/functions]} ]]; then
#  fpath=("${ZDOTDIR:-$HOME/}/functions" "${fpath[@]}")
#fi

#  builtin setopt local_options extended_glob no_short_loops rc_quotes 
#
#  local f; for f in "$@"; do
#  (( $+functions[$f] )) && { builtin print -Pn -- ${f}; break; }
#   done
#
#  # Set local options and silence typeset output
#  setopt local_options typeset_silent
#  typeset init_path
#
#  # Autoload all functions from the functions directory
#  for init_path in "${ZDOTDIR:-$HOME/.zsh}/functions"/*; do
#    autoload -Uz "${init_path##*/}"
#  done
#}
#autoload_lazyload

HISTFILE="${ZI[CACHE_DIR]}/.zsh_history"
[[ -e $HISTFILE ]] || { command mkdir -p ${HISTFILE:h}; command touch $HISTFILE; }
[[ -w $HISTFILE ]] && typeset -gx SAVEHIST=440000 HISTSIZE=441000 HISTFILE

reinitialize_compinit() {
    ZI[ZCOMPDUMP_PATH]="${ZI[ZCOMPDUMP_PATH]:-${ZI[CACHE_DIR]}/.zcompdump}"

    # Check if the .zcompdump file exists and needs to be updated
    if [[ -f "$ZI[ZCOMPDUMP_PATH]" ]]; then
        local zcompdump_age=$(( $(date +%s) - $(date -r "$ZI[ZCOMPDUMP_PATH]" +%s) ))
        if (( zcompdump_age > 86400 )); then # More than a day old
            rm -f "$ZI[ZCOMPDUMP_PATH]"
            echo "Deleted old .zcompdump to allow regeneration."
        fi
        # In both cases (file deleted or not), zi will handle compinit and regeneration of .zcompdump
    fi
    # No need to explicitly call compinit as zi manages this automatically
    # However, you might want to ensure zi's automatic compinit and compdef management is enabled
}
reinitialize_compinit

select_p10k_theme() {
  local host_p10k_theme="$HOME/.zsh/themes/host_p10k.zsh"
  local docker_p10k_theme="$HOME/.zsh/themes/docker_p10k.zsh"

  if [ -f "/.dockerenv" ] || grep -q -e docker -e '/docker/' /proc/1/cgroup 2>/dev/null; then
    if [[ -f $docker_p10k_theme ]]; then
      source $docker_p10k_theme
    fi
  else
    if [[ -f $host_p10k_theme ]]; then
      source $host_p10k_theme
    fi
  fi
}
select_p10k_theme
