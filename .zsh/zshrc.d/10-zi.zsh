# Global configuration for Zi
# Definitionen und Erläuterungen zu verschiedenen Zi-Befehlen und -Eigenschaften
# wait	          Laden Sie 0 Sekunden (genau etwa 5 ms) nach der Eingabeaufforderung ( Turbomodus ).
# lucid	          Schalten Sie die untergeordneten Meldungen stumm (" Loaded {name of the plugin}").
# light-mode	  Laden Sie das Plugin ein lightModus. 1 .
# atpull'…'	  Nach der Aktualisierung des Plugins ausführen – der Befehl im Ice installiert alle neuen Vervollständigungen.
# atinit'…'	  Führen Sie den Code aus, bevor Sie das Plugin laden.
# atload'…'  	  Führen Sie den Code aus, nachdem Sie das Plugin geladen haben.
# zicompinit	  Ist gleich autoload compinit; compinit.
# zicdreplay	  Ausführen compdef …Aufrufe durch Plugins.

# atclone         Führen Sie den Befehl nach dem Klonen im Plugin-Verzeichnis aus, z. B zi ice atclone"echo cloned". Läuft auch nach dem Herunterladen des Snippets.
# atpull 	  Führen Sie den Befehl nach der Aktualisierung (nur für neue Commits) im Verzeichnis des Plugins aus.Wenn es mit „!“ beginnt dann wird der Befehl 
#                 vorher ausgeführt mv& cpEis und davor git pulloder svn update. Ansonsten wird nachgelaufen mv& cpEis. 
#                 Benutzen Sie die atpull'%atclone'wiederholen atcloneEismodifikator.
# atinit 	  Führen Sie den Befehl nach der Verzeichniseinrichtung (Klonen, Überprüfen usw.) des Plugins/Snippets aus, bevor Sie es laden.
# atload 	  Führen Sie nach dem Laden den angegebenen Befehl im Verzeichnis des Plugins aus. Kann mit Snippets verwendet werden. 
#                 Dem übergebenen Code kann Folgendes vorangestellt werden !, zu untersuchen (bei Verwendung load, nicht light). 


# Definiere globale Zi-Konfigurationen
typeset -gA ZI
ZI[HOME_DIR]="$HOME/.zi"                            # Definiere das Heimverzeichnis für Zi
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"                   # Definiere das Binärverzeichnis für Zi
ZI[CONFIG_DIR]="$HOME/.config/zi"                   # Definiere das Konfigurationsverzeichnis für Zi
ZI[CACHE_DIR]="$HOME/.cache/zi"                     # Definiere das Cache-Verzeichnis für Zi
ZI[ZCOMPDUMP_PATH]="${ZI[ZCOMPDUMP_PATH]:-${ZI[CACHE_DIR]}/.zcompdump}"
ZI[REPOSITORY]="https://github.com/z-shell/zi.git"  # Zi's Git Repository URL
ZI[STREAM]="main"                                   # Git Stream (Branch) zu verwenden

if command -v zi &> /dev/null; then
local missing_cmds=()
for cmd in git curl wget unzip; do
  if ! command -v $cmd &> /dev/null; then
    missing_cmds+=("$cmd")
  fi
done
fi

if (( ${#missing_cmds[@]} > 0 )); then
  print -P "%F{yellow}Warning: The following command(s) are missing:%f"
  for cmd in "${missing_cmds[@]}"; do
    print -P "%F{red}- $cmd%f"
  done
  print -P "%F{yellow}These commands are essential for Zi initialization. Please install them before continuing.%f"
  
  read -q "REPLY?Do you want to continue anyway? (y/n): "
  echo # Move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    print -P "%F{green}Continuing with Zi initialization...%f"
  else
    print -P "%F{red}Aborting Zi initialization.%f"
    return 1
  fi
fi

if [[ ! -f "${ZI[HOME_DIR]}/zi.zsh" ]]; then
    echo "Zi wird installiert..."
    git clone --depth 1 "${ZI[REPOSITORY]}" "${ZI[HOME_DIR]}" || {
        echo "Fehler beim Klonen von Zi. Überprüfe deine Internetverbindung und Zugriffsrechte."
        return 1
    }
fi

source "${ZI[HOME_DIR]}/zi.zsh"
autoload -Uz _zi
#(( ${+_comps} )) && _zi register-completion zi
mkdir -p "$ZI[HOME_DIR]" "$ZI[BIN_DIR]" "$ZI[CACHE_DIR]" "$ZI[CONFIG_DIR]"


# THEME
zi ice if"[ \"${TERM##*-}\" = '256color' ] || [ \"${terminfo[colors]:?}\" -gt 255 ]"
zi light romkatv/powerlevel10k
# FONT FOR THEME
if [[ ! -d ${HOME}/.fonts/ttf ]]; then mkdir -p ${HOME}/.fonts/ttf; fi
if command -v fc-list >/dev/null 2>&1; then
  zi ice if"[[ -d ${HOME}/.fonts/ttf ]] && [[ $OSTYPE = linux* ]]" \
    id-as"meslo" from"gh-r" bpick"Meslo.zip" extract nocompile depth"1" \
    atclone="rm -f *Windows*; mv -vf *.ttf ${HOME}/.fonts/ttf/; fc-cache -v -f" atpull="%atclone"
  zi light ryanoasis/nerd-fonts
else
  echo "Fontconfig (fc-list) ist nicht installiert. Bitte installieren Sie Fontconfig, um fortzufahren."
fi
# ANNEX
zi light-mode compile'functions/.*za-*~*.zwc' for z-shell/z-a-meta-plugins @annexes
# OH-MY-ZSH PLUGINS 
zi snippet 'OMZL::completion.zsh'
zi-turbo '0a' light-mode for \
  atload"unalias grv g" OMZP::git \
  if'[[ -d ~/.gnupg ]]' OMZP::gpg-agent \
&& zi is-snippet wait lucid for \
  atload"unalias grv g" \
  OMZP::{git,golang,z,vscode,copyfile,copybuffer,compleat,common-aliases,sudo,extract,pip,wp-cli,flutter,github,copypath,gh,dirhistory,mosh,nmap,web-search} \
  if'[[ -d ~/.ssh ]]' OMZP::ssh-agent \
  if'[[ -d ~/.gnupg ]]' OMZP::gpg-agent \
  if'[[ "$OSTYPE" = *-gnu ]]' OMZP::gnu-utils \
  has'pip' OMZP::pip \
  has'python' OMZP::python
# PLUGINS
zi-turbo '0a' for \
  binary sbin'bin/*' \
    z-shell/nb \
  binary from"gh-r" sbin \
    ajeetdsouza/zoxide \
  has'zoxide' \
    z-shell/zsh-zoxide \
  has'lsd' atinit'AUTOCD=1' \
    z-shell/zsh-lsd \
  atinit'YSU_MESSAGE_POSITION=after' \
    MichaelAquilina/zsh-you-should-use

zi wait lucid for \
    atinit"ZI[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    "zdharma-continuum/fast-syntax-highlighting" \
    "zsh-users/zsh-completions" \
    "zsh-users/zsh-autosuggestions" \
    atload"!_zsh_autosuggest_start" \
    "le0me55i/zsh-extract"
    
    zi as"null" lucid \
  atinit'export PYENV_ROOT="$HOME/.pyenv";
          mkdir -p "$PYENV_ROOT";
          if [[ ! -d "$PYENV_ROOT" ]]; then
            echo "pyenv is not installed. Installing...";
            git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT";
          fi;
          if [[ ! -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]]; then
            echo "pyenv-virtualenv is not found. Downloading...";
            git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT/plugins/pyenv-virtualenv";
          fi;
          export PATH="$PYENV_ROOT/bin:$PATH";
          eval "$(pyenv init --path)";
          eval "$(pyenv virtualenv-init -)"' \
  atclone'PYENV_ROOT="$HOME/.pyenv"; ./libexec/pyenv init - > zpyenv.zsh;
          if [[ ! -f zpyenv.zsh ]]; then
            echo "Error creating zpyenv.zsh. Please check your pyenv installation.";
          fi;
          mkdir -p "$PYENV_ROOT/plugins";
          git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT/plugins/pyenv-virtualenv"' \
  atpull'%atclone' \
  src"zpyenv.zsh" \
  nocompile'!' \
  sbin"bin/pyenv" \
  for pyenv/pyenv
# After pyenv is loaded, initialize pyenv-virtualenv automatically
if [[ -d "$(pyenv root)/plugins/pyenv-virtualenv" ]]; then
  eval "$(pyenv virtualenv-init -)"
fi

zi for atclone'mkdir -p $ZPFX/{bin,man/man1}' atpull'%atclone' from'gh-r' dl'
  https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh -> _fzf_completion;
  https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh -> key-bindings.zsh;
  https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf-tmux.1 -> $ZI[MAN_DIR]/man1/fzf-tmux.1;
  https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf.1 -> $ZI[MAN_DIR]/man1/fzf.1' \
    id-as'junegunn/fzf' nocompile pick'/dev/null' sbin'fzf' src'key-bindings.zsh' \
      junegunn/fzf

zi from"gh-r" as"null" for \
  sbin"**/fd" @sharkdp/fd \
  sbin"**/bat" @sharkdp/bat \
  sbin"**/exa -> exa" atclone"cp -vf completions/exa.zsh _exa" ogham/exa

zi ice rustup cargo'!atuin' id-as'atuin' as'program' nocompile
zi load z-shell/0
eval "$(atuin init zsh)"

# navi: Interactive cheatsheet tool for command-line and application commands.
zi ice lucid wait as'program' from"gh-r" has'fzf'
zi load denisidoro/navi
[[ -d ~/.local/share/navi/cheats/${USER}__cheats ]] && export CHEATS="$HOME/.local/share/navi/cheats/${USER}__cheats"

# Conditional jq installation: Only installs jq if not already present.
zi wait lucid for if"(( ! ${+commands[jq]} ))" as"null" \
  atclone"autoreconf -fi && ./configure --with-oniguruma=builtin && make \
  && ln -sfv $PWD/jq.1 $ZI[MAN_DIR]/man1" sbin"jq" \
    stedolan/jq

# Additional tools and plugins, each providing unique functionality to enhance the shell experience.
# gotcha: Command recall tool for easier command navigation.
zi ice as'program' from'gh-r' mv'gotcha_* -> gotcha'
zi light babarot/gotcha

# httpstat: Visualizes HTTP request statistics for debugging and analysis.
zi ice as"program" cp"httpstat.sh -> httpstat" pick"httpstat"
zi light b4b4r07/httpstat

# Überprüft, ob tmux installiert ist, und lädt tmux-bezogene Plugins
if zi ice lucid wait as'completion' blockf has'tmux'; then
  zi light greymd/tmux-xpanes
fi
