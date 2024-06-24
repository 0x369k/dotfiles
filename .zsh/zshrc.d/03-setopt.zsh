# Zsh Optionen
setopt bang_hist                # Behandelt das '!' Zeichen bei der Expansion
setopt extended_glob            # Behandelt #, ~, und ^ als Teil von Dateinamenmustern
setopt no_glob_dots             # "*" soll keine Dateien, die mit "." beginnen, in Vervollständigungen einbeziehen
setopt no_sh_word_split         # Verwende Zsh-Stil Worttrennung
setopt always_to_end            # Verschiebt den Cursor ans Ende der Wörter bei Vervollständigungen
setopt auto_list                # Listet automatisch Optionen bei einer unklaren Vervollständigung
setopt auto_cd                  # Führt 'cd' aus, wenn der Verzeichnisname eingegeben wird
setopt hist_expire_dups_first   # Löscht doppelte Einträge zuerst, wenn die HISTFILE Größe überschritten wird
setopt hist_ignore_all_dups     # Entfernt ältere doppelte Einträge aus der Historie
setopt hist_ignore_dups         # Ignoriert doppelte Befehle in der Historie
setopt hist_ignore_space        # Ignoriert Befehle, die mit einem Leerzeichen beginnen
setopt hist_reduce_blanks       # Entfernt überflüssige Leerzeichen aus Historieeinträgen
setopt hist_save_no_dups        # Speichert keine doppelten Einträge in der Historie
setopt hist_verify              # Zeigt den Befehl mit Historienerweiterung vor der Ausführung an
setopt share_history            # Teilt die Historiedaten
setopt append_history           # Ermöglicht mehreren Terminalsitzungen, zur Historie hinzuzufügen
setopt extended_history         # Speichert den Zeitstempel des Befehls in HISTFILE
setopt inc_append_history       # Stellt sicher, dass Befehle sofort zur Historie hinzugefügt werden
setopt interactive_comments     # Ermöglicht Kommentare in interaktiven Shells
setopt prompt_subst             # Ermöglicht Parameterexpansion, Befehlsersetzung und arithmetische Expansion im Prompt
setopt pushd_ignore_dups        # Fügt keine mehrfachen Kopien desselben Verzeichnisses zum Verzeichnisstapel hinzu
setopt long_list_jobs           # Zeigt die PID an, wenn Prozesse angehalten werden
setopt no_sh_word_split         # Verwende Zsh-Stil Worttrennung
setopt unset                    # Fehler nicht, wenn nicht gesetzte Parameter verwendet werden
setopt notify                   # Meldet den Status von Hintergrundprozessen sofort
setopt nohup                    # Sendet kein SIGHUP an Hintergrundprozesse, wenn die Shell beendet wird
setopt ignore_eof               # Verhindert, dass die Shell durch Drücken von Ctrl-D beendet wird
setopt NO_CASE_GLOB             # Ignoriert Groß-/Kleinschreibung bei der Dateisuche mit Globbing
unsetopt rm_star_silent         # Fragt nach Bestätigung bei 'rm *' und 'rm path/'
setopt local_options extended_glob no_short_loops rc_quotes
# Zsh Optionen
setopt bang_hist                # Behandelt das '!' Zeichen bei der Expansion
setopt extended_glob            # Behandelt #, ~, und ^ als Teil von Dateinamenmustern
setopt no_glob_dots             # "*" soll keine Dateien, die mit "." beginnen, in Vervollständigungen einbeziehen
setopt no_sh_word_split         # Verwende Zsh-Stil Worttrennung
setopt always_to_end            # Verschiebt den Cursor ans Ende der Wörter bei Vervollständigungen
setopt auto_list                # Listet automatisch Optionen bei einer unklaren Vervollständigung
setopt auto_cd                  # Führt 'cd' aus, wenn der Verzeichnisname eingegeben wird
setopt hist_expire_dups_first   # Löscht doppelte Einträge zuerst, wenn die HISTFILE Größe überschritten wird
setopt hist_ignore_all_dups     # Entfernt ältere doppelte Einträge aus der Historie
setopt hist_ignore_dups         # Ignoriert doppelte Befehle in der Historie
setopt hist_ignore_space        # Ignoriert Befehle, die mit einem Leerzeichen beginnen
setopt hist_reduce_blanks       # Entfernt überflüssige Leerzeichen aus Historieeinträgen
setopt hist_save_no_dups        # Speichert keine doppelten Einträge in der Historie
setopt hist_verify              # Zeigt den Befehl mit Historienerweiterung vor der Ausführung an
setopt share_history            # Teilt die Historiedaten
setopt append_history           # Ermöglicht mehreren Terminalsitzungen, zur Historie hinzuzufügen
setopt extended_history         # Speichert den Zeitstempel des Befehls in HISTFILE
setopt inc_append_history       # Stellt sicher, dass Befehle sofort zur Historie hinzugefügt werden
setopt interactive_comments     # Ermöglicht Kommentare in interaktiven Shells
setopt prompt_subst             # Ermöglicht Parameterexpansion, Befehlsersetzung und arithmetische Expansion im Prompt
setopt pushd_ignore_dups        # Fügt keine mehrfachen Kopien desselben Verzeichnisses zum Verzeichnisstapel hinzu
setopt long_list_jobs           # Zeigt die PID an, wenn Prozesse angehalten werden
setopt no_sh_word_split         # Verwende Zsh-Stil Worttrennung
setopt unset                    # Fehler nicht, wenn nicht gesetzte Parameter verwendet werden
setopt notify                   # Meldet den Status von Hintergrundprozessen sofort
setopt nohup                    # Sendet kein SIGHUP an Hintergrundprozesse, wenn die Shell beendet wird
setopt ignore_eof               # Verhindert, dass die Shell durch Drücken von Ctrl-D beendet wird
setopt NO_CASE_GLOB             # Ignoriert Groß-/Kleinschreibung bei der Dateisuche mit Globbing
unsetopt rm_star_silent         # Fragt nach Bestätigung bei 'rm *' und 'rm path/'
setopt local_options extended_glob no_short_loops rc_quotes
